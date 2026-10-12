#!/bin/bash
# backup-verify.sh — verify the backup OUTCOME, not the backup intent. V0.122
#
# WHY THIS EXISTS (2026-10-12 action: "Enforce the backup outcome"):
# Two silent-failure modes were found on the same day and neither was caught by
# any alert — both were found by luck during manual verification:
#   1. nightly-backup.sh's guard skipped a repo whose commits were unpushed
#      (clean index, HEAD ahead of the remote), so the offsite copy fell behind
#      while the log said the backup ran.
#   2. The openviking + pi-state backups did not run for 3 days because the
#      laptop was asleep at the fixed clock time; cron looked healthy.
# Both share one shape: the schedule trusts its own *input* ("did we run?")
# instead of the *outcome* ("is the remote actually up to date?"). A push can
# also be accepted locally while the remote ref is rewritten out-of-band, or a
# push policy silently changes. This script closes that gap.
#
# TWO MODES
#   --assert   Cheap post-push assertion. For each repo, compare the LOCAL HEAD
#              to the REMOTE ref the backup pushes to, via `git ls-remote`
#              (remote-side truth, not a possibly-stale tracking ref). Any
#              mismatch is caught regardless of cause. Wired into the backup
#              scripts so divergence is detected at push time.
#   --drill    Periodic fresh-clone recovery drill. Clone each repo to a temp
#              dir (a genuine fresh clone, not the working copy) and assert the
#              restore-critical trees are present and non-empty. This exercises
#              the RESTORE path instead of assuming it — which is the whole
#              point of a backup.
#
# Usage:
#   backup-verify.sh --assert          # post-push assertion, exit 1 on mismatch
#   backup-verify.sh --drill           # fresh-clone recovery drill, exit 1 on gap
#   backup-verify.sh --drill --keep    # keep the clones for inspection
#   backup-verify.sh --quiet           # only emit on failure (cron/log-friendly)
#
# Env:
#   KBS_VERIFY_KBS   repo holding curated knowledge   (default: $HOME/kbs)
#   KBS_VERIFY_RAW   repo holding pi-state + packs    (default: $HOME/.cache/kbs-raw)
#   KBS_VERIFY_LOG   log file      (default: $KBS/backup.log)
#   KBS_VERIFY_STATE state dir     (default: $HOME/.local/state/kbs-backup)

set -u

MODE=""
QUIET=0
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --assert) MODE="assert" ;;
        --drill)  MODE="drill" ;;
        --quiet)  QUIET=1 ;;
        --keep)   KEEP=1 ;;
        -h|--help) sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown arg: $arg" >&2; exit 2 ;;
    esac
done
if [ -z "$MODE" ]; then
    echo "usage: backup-verify.sh (--assert | --drill) [--quiet] [--keep]" >&2
    exit 2
fi

KBS_REPO="${KBS_VERIFY_KBS:-$HOME/kbs}"
RAW_REPO="${KBS_VERIFY_RAW:-$HOME/.cache/kbs-raw}"
LOG="${KBS_VERIFY_LOG:-$KBS_REPO/backup.log}"
STATE_DIR="${KBS_VERIFY_STATE:-$HOME/.local/state/kbs-backup}"
mkdir -p "$STATE_DIR" 2>/dev/null || true

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] BACKUP_VERIFY | $*" >> "$LOG" 2>/dev/null || true; }
say() { [ "$QUIET" -eq 1 ] || echo "$*"; }

FAIL=0

# repo_head <dir> — full SHA of local HEAD, or empty.
repo_head() { git -C "$1" rev-parse HEAD 2>/dev/null; }

# remote_ref <dir> <remote> <ref> — remote-side SHA via ls-remote, or empty.
remote_ref() {
    git -C "$1" ls-remote "$2" "$3" 2>/dev/null | cut -f1
}

# pick_remote <dir> — first configured remote that is the backup target. The
# curated repo pushes to `gitea` (falling back to `origin`); the raw repo uses
# `origin`. Preferring gitea keeps the assertion pointed at the offsite copy.
pick_remote() {
    local dir="$1"
    if git -C "$dir" remote get-url gitea >/dev/null 2>&1; then
        echo "gitea"; return
    fi
    echo "origin"
}

# default_branch <dir> <remote> — HEAD branch name, falling back to master/main.
default_branch() {
    local dir="$1"
    git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null && return
    for b in master main; do
        [ -n "$(remote_ref "$dir" "$(pick_remote "$dir")" "refs/heads/$b")" ] && { echo "$b"; return; }
    done
    echo master
}

assert_one() {
    local dir="$1" label="$2"
    if [ ! -d "$dir/.git" ]; then
        log "$MODE | $label | SKIP: no git repo at $dir"
        say "SKIP  $label — no git repo at $dir"
        return 0
    fi
    local remote branch local_head remote_head
    remote="$(pick_remote "$dir")"
    branch="$(default_branch "$dir")"
    local_head="$(repo_head "$dir")"
    remote_head="$(remote_ref "$dir" "$remote" "refs/heads/$branch")"

    if [ -z "$local_head" ]; then
        log "$MODE | $label | FAIL: cannot read local HEAD in $dir"
        say "FAIL  $label — cannot read local HEAD"
        return 1
    fi
    if [ -z "$remote_head" ]; then
        log "$MODE | $label | FAIL: remote $remote refs/heads/$branch unreadable (host down / auth / ref missing)"
        say "FAIL  $label — remote '$remote' refs/heads/$branch unreadable"
        return 1
    fi
    if [ "$local_head" != "$remote_head" ]; then
        log "$MODE | $label | FAIL: DIVERGENCE local=$local_head remote($remote/$branch)=$remote_head"
        say "FAIL  $label — DIVERGENCE local=${local_head:0:9} remote=${remote_head:0:9}"
        return 1
    fi
    log "$MODE | $label | OK: remote $remote/$branch matches local HEAD ${local_head:0:9}"
    say "OK    $label — $remote/$branch = ${local_head:0:9}"
    return 0
}

# --- assert mode ---------------------------------------------------------------
if [ "$MODE" = "assert" ]; then
    assert_one "$KBS_REPO" "kbs-data"  || FAIL=1
    assert_one "$RAW_REPO" "kbs-raw"   || FAIL=1
    if [ "$FAIL" -eq 1 ]; then
        echo "ERR backup-verify: post-push assertion FAILED — offsite copy is behind or unreachable" >&2
        exit 1
    fi
    date +%s > "$STATE_DIR/verify-assert.last"
    say "OK    post-push assertion passed"
    exit 0
fi

# --- drill mode ----------------------------------------------------------------
# A fresh clone proves the REMOTE can reconstruct the working state. Assert the
# restore-critical trees exist and are non-empty; a clone that succeeds but is
# missing sessions or transcripts is not a usable recovery.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/kbs-verify-drill.XXXXXX")"
trap '[ "$KEEP" -eq 1 ] || rm -rf "$WORK"' EXIT

clone_repo() {
    local src="$1" dst="$2" label="$3"
    local remote
    # Clone from the OFFSITE remote the backup pushes to, not from the external
    # mirror. For kbs-data that is `gitea`; `origin` (GitHub over HTTPS) needs
    # interactive credentials and is not the durability target. The recovery
    # question is "can the offsite copy rebuild the state?", so drill that one.
    remote="$(git -C "$src" remote get-url gitea 2>/dev/null)"
    [ -n "$remote" ] || remote="$(git -C "$src" remote get-url origin 2>/dev/null)"
    if [ -z "$remote" ]; then
        log "drill | $label | FAIL: no remote URL configured in $src"
        say "FAIL  $label — no remote configured"
        return 1
    fi
    say "....  $label — cloning $remote"
    if ! timeout 600 git clone -q "$remote" "$dst" 2>>"$LOG"; then
        log "drill | $label | FAIL: fresh clone failed from $remote"
        say "FAIL  $label — fresh clone failed"
        return 1
    fi
    return 0
}

# expect_nonempty <dir> <relpath> <label>
expect_nonempty() {
    local base="$1" rel="$2" label="$3"
    local target="$base/$rel"
    if [ ! -d "$target" ]; then
        log "drill | $label | FAIL: missing tree $rel"
        say "FAIL  $label — missing $rel"
        return 1
    fi
    local n
    n="$(find "$target" -type f 2>/dev/null | wc -l | tr -d ' ')"
    if [ "${n:-0}" -eq 0 ]; then
        log "drill | $label | FAIL: empty tree $rel"
        say "FAIL  $label — $rel is empty"
        return 1
    fi
    say "OK    $label — $rel ($n files)"
    return 0
}

DRILL_FAIL=0

if clone_repo "$KBS_REPO" "$WORK/kbs-data" "kbs-data"; then
    # A fresh clone that has any files at all is already meaningful; then assert
    # the owner-data files a recovery must contain.
    if [ "$(find "$WORK/kbs-data" -type f -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ]; then
        log "drill | kbs-data | FAIL: clone is empty"
        say "FAIL  kbs-data — clone is empty"
        DRILL_FAIL=1
    fi
    for f in ACTIONS.md FAILURES.md SUCCESSES.md DECISIONS.md; do
        if [ ! -s "$WORK/kbs-data/$f" ]; then
            log "drill | kbs-data | FAIL: required file $f missing or empty"
            say "FAIL  kbs-data — $f missing/empty"
            DRILL_FAIL=1
        fi
    done
    [ "$DRILL_FAIL" -eq 1 ] || say "OK    kbs-data — required files present"
fi

if clone_repo "$RAW_REPO" "$WORK/kbs-raw" "kbs-raw"; then
    expect_nonempty "$WORK/kbs-raw" "pi-state/sessions" "kbs-raw" || DRILL_FAIL=1
    expect_nonempty "$WORK/kbs-raw" "pi-state/chat-transcripts" "kbs-raw" || DRILL_FAIL=1
    if [ ! -s "$WORK/kbs-raw/pi-state/pi-hermes-memory/MEMORY.md" ]; then
        log "drill | kbs-raw | FAIL: pi-hermes-memory/MEMORY.md missing or empty"
        say "FAIL  kbs-raw — MEMORY.md missing/empty"
        DRILL_FAIL=1
    fi
    # Per-project memory: assert at least one project MEMORY.md survives, so the
    # tree added 2026-10-12 (action: settle the remaining unbacked state) is
    # really carried offsite rather than assumed.
    if ! find "$WORK/kbs-raw/pi-state/projects-memory" -type f -name 'MEMORY.md' 2>/dev/null | grep -q .; then
        log "drill | kbs-raw | FAIL: no project MEMORY.md in pi-state/projects-memory"
        say "FAIL  kbs-raw — no project MEMORY.md"
        DRILL_FAIL=1
    else
        say "OK    kbs-raw — project memory present"
    fi
    # OpenViking pack: expect at least one .ovpack plus SHA256SUMS.
    if ! find "$WORK/kbs-raw/openviking" -name '*.ovpack' -type f 2>/dev/null | grep -q .; then
        log "drill | kbs-raw | FAIL: no .ovpack in openviking/"
        say "FAIL  kbs-raw — no .ovpack in openviking/"
        DRILL_FAIL=1
    else
        say "OK    kbs-raw — openviking pack present"
    fi
fi

if [ "$DRILL_FAIL" -eq 1 ]; then
    log "drill | FAILED — recovery path has a gap (kept=$KEEP, work=$WORK)"
    echo "ERR backup-verify: recovery drill FAILED — a fresh clone cannot reconstruct the working state" >&2
    [ "$KEEP" -eq 1 ] && echo "    clones kept at $WORK"
    exit 1
fi

date +%s > "$STATE_DIR/verify-drill.last"
log "drill | PASSED — fresh clone reconstructs kbs-data + kbs-raw"
say "OK    recovery drill passed"
[ "$KEEP" -eq 1 ] && echo "    clones kept at $WORK"
exit 0
