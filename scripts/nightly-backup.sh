#!/bin/bash
# KBS Nightly Backup — commit the data repo (kbs-data) if anything changed.
#
# POLICY: a data repo may have BOTH an offsite remote (private,
# self-hosted) and an external one (`origin`, e.g. GitHub).
#
#   - The offsite remote (when present) is pushed by DEFAULT — it is the offsite durability
#     path. Set KBS_OFFSITE_PUSH=0 to disable.
#   - `origin` stays gated behind KBS_ALLOW_EXTERNAL_PUSH=1, so org-sensitive
#     content is never published to an external host by accident.
#
# A self-hosted remote is the right offsite target when the data mixes personal
# and org material that must not go to a public host or employer infrastructure.
# See docs/backup-and-restore.md.
#
# Generous cron: @reboot + 12:45,16:45 (laptop up ~8-10h/day; 23:45 was missed).
#
# Auth: repo-local credential helper (scripts/git-credential-env.sh) serves
# tokens from the git-ignored .env — no
# interactive login needed, and no secret is written to .git/config.
# Local run log: ~/kbs/backup.log (git-ignored via *.log).
#
# Configurable remote and branch:
#   KBS_OFFSITE_REMOTE  — offsite remote name (default: offsite)
#   KBS_BRANCH           — branch to push (default: current HEAD branch)

set -u

# Portable timeout: GNU `timeout` (Linux), `gtimeout` (Homebrew/coreutils on macOS),
# or no limit if neither is installed (stock macOS).
if command -v timeout >/dev/null 2>&1; then run_timeout() { timeout "$@"; }
elif command -v gtimeout >/dev/null 2>&1; then run_timeout() { gtimeout "$@"; }
else run_timeout() { local _d="$1"; shift; "$@"; }
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# Configurable offsite remote and branch
OFFSITE_REMOTE="${KBS_OFFSITE_REMOTE:-offsite}"
BRANCH="${KBS_BRANCH:-$(git symbolic-ref --short HEAD 2>/dev/null || echo master)}"

TS="$(date '+%Y-%m-%d %H:%M:%S')"
LOG="$ROOT/backup.log"

# Ensure the portable credential helper is configured (survives fresh clones)
if [ "$(git config credential.helper)" != "!bash scripts/git-credential-env.sh" ]; then
    git config credential.helper '!bash scripts/git-credential-env.sh'
fi

# Refresh system-owned files from the system repo before committing, so the
# data repo is always committed at the current system version ("fix upstream,
# sync down"). Without this, system-file drift lands as a data-repo commit.
# Best-effort: a sync failure must never abort the backup, but it is logged.
# Set KBS_PREBACKUP_SYNC=0 to skip.
if [ "${KBS_PREBACKUP_SYNC:-1}" = "1" ] && [ -x "$ROOT/scripts/kbs-sync.sh" ]; then
    if SYNC_OUT="$(bash "$ROOT/scripts/kbs-sync.sh" 2>&1)"; then
        echo "[$TS] BACKUP | pre-backup sync: $(printf '%s' "$SYNC_OUT" | tail -1)" >> "$LOG"
    else
        echo "[$TS] BACKUP | PRE-BACKUP SYNC FAILED (continuing): $(printf '%s' "$SYNC_OUT" | tail -3 | tr '\n' ' ')" >> "$LOG"
    fi
fi

git add -A

# Decide whether there is anything to do. Two distinct cases, and conflating
# them silently skips the push:
#   1. uncommitted working-tree changes  -> commit then push
#   2. already-committed, unpushed local commits -> push only
# A bare `git diff --cached --quiet` guard catches only case 1. When the owner
# commits manually before the backup runs, the index is clean, the guard trips,
# and the script exits WITHOUT pushing — leaving the offsite remote behind while
# the log cheerfully reports "no changes". Ops must therefore also compare HEAD
# against the upstream tracking ref.
COMMITTED_ONLY=0
if git diff --cached --quiet; then
    # Nothing staged. Is HEAD ahead of the offsite remote (or is there no
    # upstream ref locally yet)? If so there are still commits to publish.
    if git remote get-url "$OFFSITE_REMOTE" >/dev/null 2>&1; then
        AHEAD="$(git rev-list --count "refs/remotes/$OFFSITE_REMOTE/$BRANCH..HEAD" 2>/dev/null || echo unknown)"
        if [ "$AHEAD" = "unknown" ]; then
            # No local tracking ref (e.g. never fetched/pushed from here): ask the
            # remote directly, so a fresh clone still publishes correctly.
            REMOTE_HEAD="$(git ls-remote "$OFFSITE_REMOTE" "refs/heads/$BRANCH" 2>/dev/null | cut -f1)"
            if [ -n "$REMOTE_HEAD" ] && [ "$REMOTE_HEAD" != "$(git rev-parse HEAD)" ]; then
                COMMITTED_ONLY=1
            fi
        elif [ "${AHEAD:-0}" -gt 0 ] 2>/dev/null; then
            COMMITTED_ONLY=1
        fi
    fi

    if [ "$COMMITTED_ONLY" -eq 0 ]; then
        echo "[$TS] BACKUP | no changes" >> "$LOG"
        exit 0
    fi
fi

if [ "$COMMITTED_ONLY" -eq 1 ]; then
    # Case 2: nothing to commit. Publish the commits that already exist locally.
    SUMMARY="$(git log --oneline -1 | sed 's/^ */committed: /')"
    echo "[$TS] BACKUP | pending commits, no working-tree changes" >> "$LOG"
else
    SUMMARY="$(git diff --cached --stat | tail -1 | sed 's/^ *//')"
    git commit -q -m "Nightly backup $(date '+%Y-%m-%d')

$SUMMARY"
fi

# Offsite push to the self-hosted remote (`gitea`) when configured.
# Generic form: no host is hardcoded. The pre-push probe derives the endpoint
# from the remote URL (or resolves an ssh alias), so this works for any Gitea.
OFFSITE_FAIL=0
if [ "${KBS_OFFSITE_PUSH:-1}" = "1" ] && git remote get-url "$OFFSITE_REMOTE" >/dev/null 2>&1; then
    # PRE-PUSH REACHABILITY CHECK: a closed firewall port can make external SYNs
    # vanish, so a push fails with only a generic error. Probe first so the log
    # names the cause, and hint at the fix when we recognise it. A probe failure
    # is advisory only — the push below still decides the outcome.
    OFFSITE_URL="$(git remote get-url "$OFFSITE_REMOTE")"
    PROBE_HOST=""; PROBE_PORT=22
    case "$OFFSITE_URL" in
        ssh://*)
            after="${OFFSITE_URL#ssh://}"; authority="${after%%/*}"
            PROBE_HOST="${authority#*@}"; PROBE_HOST="${PROBE_HOST%%:*}"
            case "$authority" in *:*) PROBE_PORT="${authority##*:}" ;; esac
            ;;
    esac

    PROBE_OK=0
    if [ -n "$PROBE_HOST" ]; then
        # If it is an ssh_config alias, resolve it to its real host and port.
        RH="$(ssh -G "$PROBE_HOST" 2>/dev/null | awk '/^hostname /{print $2; exit}')"
        RP="$(ssh -G "$PROBE_HOST" 2>/dev/null | awk '/^port /{print $2; exit}')"
        [ -n "${RH:-}" ] && [ "$RH" != "$PROBE_HOST" ] && { PROBE_HOST="$RH"; PROBE_PORT="$RP"; }
        if run_timeout 15 bash -c "cat < /dev/null > /dev/tcp/$PROBE_HOST/$PROBE_PORT" 2>/dev/null; then
            PROBE_OK=1
        fi
    fi

    if [ "$PROBE_OK" -eq 0 ]; then
        echo "[$TS] BACKUP | OFFSITE REMOTE UNREACHABLE at $PROBE_HOST:$PROBE_PORT (host down, firewall, or tunnel); attempting push anyway | $SUMMARY" >> "$LOG"
    fi

    if git push -q "$OFFSITE_REMOTE" "$BRANCH" 2>> "$LOG"; then
        echo "[$TS] BACKUP | pushed to offsite $OFFSITE_REMOTE | $SUMMARY" >> "$LOG"
        # Post-push ASSERTION: confirm the remote ref actually advanced to our
        # HEAD. A push can be accepted locally while the remote ref is rewritten
        # out-of-band or a push policy silently changes; trusting the local exit
        # code alone re-creates the same "green schedule, stale offsite" gap this
        # action exists to close. (2026-10-12 action: enforce the backup outcome.)
        if [ -x "$ROOT/scripts/backup-verify.sh" ]; then
            if ! "$ROOT/scripts/backup-verify.sh" --assert --quiet 2>>"$LOG"; then
                echo "[$TS] BACKUP | POST-PUSH ASSERTION FAILED — offsite copy is behind or unreachable | $SUMMARY" >> "$LOG"
                OFFSITE_FAIL=1
            fi
        fi
    else
        ERR="$(git push "$OFFSITE_REMOTE" "$BRANCH" 2>&1 | tail -3 | tr '\n' ' ')"
        echo "[$TS] BACKUP | OFFSITE PUSH FAILED | $SUMMARY | cause: ${ERR:0:300}" >> "$LOG"
        case "$ERR" in
            *"timed out"*|*"Connection refused"*)
                echo "[$TS] BACKUP |   hint: if the host answers on ssh but not the git port, check the firewall (open the git port permanently, then reload)" >> "$LOG" ;;
            *"Could not resolve"*|*"Connection reset"*)
                echo "[$TS] BACKUP |   hint: DNS/tunnel problem — check the tunnel client and the remote hostname" >> "$LOG" ;;
        esac
        OFFSITE_FAIL=1
    fi
else
    echo "[$TS] BACKUP | offsite push skipped (KBS_OFFSITE_PUSH=${KBS_OFFSITE_PUSH:-unset} or no $OFFSITE_REMOTE remote) | $SUMMARY" >> "$LOG"
fi

# External (public) push stays opt-in only.
if [ "${KBS_ALLOW_EXTERNAL_PUSH:-0}" != "1" ]; then
    echo "[$TS] BACKUP | external push disabled (KBS_ALLOW_EXTERNAL_PUSH not set) | $SUMMARY" >> "$LOG"
    [ "$OFFSITE_FAIL" -eq 1 ] && exit 1
    exit 0
fi

if git push -q origin "$BRANCH" 2>> "$LOG"; then
    echo "[$TS] BACKUP | pushed to external origin | $SUMMARY" >> "$LOG"
else
    echo "[$TS] BACKUP | EXTERNAL PUSH FAILED | $SUMMARY" >> "$LOG"
    exit 1
fi

[ "$OFFSITE_FAIL" -eq 1 ] && exit 1
exit 0