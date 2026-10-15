#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Behavioural regression tests for scripts/backup-verify.sh.
#
#   tests/test-backup-verify.sh [INSTANCE_DIR]
#
# INSTANCE_DIR is an installed KBS instance whose scripts/ dir is exercised
# (default: $KBS_PATH, else $HOME/kbs). CI passes the freshly-installed test
# instance.
#
# These tests are fully OFFLINE: they build throwaway bare repos and wire them
# as the `offsite` / `origin` remotes, so no network required.
#
# backup-verify.sh exists to catch the two silent-failure modes found on
# 2026-10-12 — a push accepted locally while the remote ref stayed behind, and a
# recovery path that had never actually been exercised. A verifier that passes
# everything would re-create exactly that blind spot, so every case here asserts
# BOTH directions: the failure it must catch, and the healthy case it must not
# flag.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

INSTANCE="${1:-${KBS_PATH:-$HOME/kbs}}"
VERIFY="$INSTANCE/scripts/backup-verify.sh"

if [ ! -x "$VERIFY" ]; then echo "ERROR: not found/executable: $VERIFY" >&2; exit 2; fi

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ✅ $1"; }
bad() { FAIL=$((FAIL+1)); echo "  ❌ $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GIT="git -c user.email=test@kbs -c user.name=test"
QUIET_ENV=(KBS_VERIFY_LOG="$WORK/backup.log" KBS_VERIFY_STATE="$WORK/state")

# make_repo <name> — create a bare "remote" plus a working clone wired to it as
# `offsite`, seeded with the files a recovery must contain.
make_repo() {
  local name="$1"
  local bare="$WORK/$name.git"
  local work="$WORK/$name"
  git init -q --bare "$bare"
  git init -q "$work"
  ( cd "$work"
    git remote add offsite "$bare"
    # seed plausible recovery content (generic names, no instance specifics)
    mkdir -p sessions chat-transcripts memory projects-memory/demo ovpack
    # kbs-data required files
    echo "# ACTIONS"      > ACTIONS.md
    echo "# FAILURES"     > FAILURES.md
    echo "# SUCCESSES"    > SUCCESSES.md
    echo "# DECISIONS"    > DECISIONS.md
    # kbs-raw content
    echo "{}"             > sessions/sess.jsonl
    echo "tx"             > chat-transcripts/t.md
    echo "# MEMORY"       > memory/MEMORY.md
    echo "# proj"         > projects-memory/demo/MEMORY.md
    echo "pack"           > ovpack/openviking-pack-test.ovpack
    echo "sums"           > ovpack/SHA256SUMS
    git -c user.email=test@kbs -c user.name=test add -A
    git -c user.email=test@kbs -c user.name=test commit -q -m seed
    git push -q -u offsite master 2>/dev/null || git push -q -u offsite HEAD:master
    git branch -M master 2>/dev/null || true
    git push -q -u offsite master
  ) >/dev/null 2>&1
  echo "$work"
}

run_verify() {
  local mode="$1"; shift
  env "${QUIET_ENV[@]}" "$@" "$VERIFY" "$mode" >/dev/null 2>&1
  echo $?
}

echo "── backup-verify.sh — --assert ──"

GOOD="$(make_repo good)"
RC="$(run_verify --assert KBS_VERIFY_KBS="$GOOD" KBS_VERIFY_RAW="$GOOD")"
[ "$RC" = "0" ] && ok "healthy repo at HEAD == remote → exit 0" \
                || bad "healthy repo should pass --assert (got rc=$RC)"

# Unpushed local commit: the exact 2026-10-12 divergence. MUST fail.
( cd "$GOOD" && $GIT commit -q --allow-empty -m "unpushed work" )
RC="$(run_verify --assert KBS_VERIFY_KBS="$GOOD" KBS_VERIFY_RAW="$GOOD")"
[ "$RC" != "0" ] && ok "unpushed commit → exit non-zero (divergence caught)" \
                 || bad "unpushed commit was NOT caught by --assert"

echo "── backup-verify.sh — --drill ──"

GOOD2="$(make_repo good2)"
RC="$(run_verify --drill KBS_VERIFY_KBS="$GOOD2" KBS_VERIFY_RAW="$GOOD2")"
[ "$RC" = "0" ] && ok "complete remote → drill passes (recovery reconstructible)" \
                || bad "complete remote should pass --drill (got rc=$RC)"

# Missing sessions tree: clone succeeds but is not a usable recovery. MUST fail.
THIN="$(make_repo thin)"
( cd "$THIN" && git rm -rq sessions && $GIT commit -q -m "drop sessions" && git push -q offsite master )
RC="$(run_verify --drill KBS_VERIFY_KBS="$THIN" KBS_VERIFY_RAW="$THIN")"
[ "$RC" != "0" ] && ok "missing sessions → drill fails (gap caught)" \
                 || bad "missing sessions tree was NOT caught by --drill"

# Missing MEMORY.md: memory is the thing most costly to lose. MUST fail.
THIN2="$(make_repo thin2)"
( cd "$THIN2" && git rm -q memory/MEMORY.md && $GIT commit -q -m "drop memory" && git push -q offsite master )
RC="$(run_verify --drill KBS_VERIFY_KBS="$THIN2" KBS_VERIFY_RAW="$THIN2")"
[ "$RC" != "0" ] && ok "missing MEMORY.md → drill fails" \
                 || bad "missing MEMORY.md was NOT caught by --drill"

# No .ovpack: the pack is unbacked. MUST fail.
THIN3="$(make_repo thin3)"
( cd "$THIN3" && git rm -rq ovpack && $GIT commit -q -m "drop pack" && git push -q offsite master )
RC="$(run_verify --drill KBS_VERIFY_KBS="$THIN3" KBS_VERIFY_RAW="$THIN3")"
[ "$RC" != "0" ] && ok "missing ovpack → drill fails" \
                 || bad "missing .ovpack was NOT caught by --drill"

# No per-project memory: the tree added 2026-10-12. MUST fail.
THIN4="$(make_repo thin4)"
( cd "$THIN4" && git rm -rq projects-memory && $GIT commit -q -m "drop project memory" && git push -q offsite master )
RC="$(run_verify --drill KBS_VERIFY_KBS="$THIN4" KBS_VERIFY_RAW="$THIN4")"
[ "$RC" != "0" ] && ok "missing project MEMORY.md → drill fails" \
                 || bad "missing project memory was NOT caught by --drill"

echo
echo "── summary ──"
echo "  passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
