#!/bin/bash
# KBS Nightly Backup — commit the data repo (kbs-data) if anything changed.
#
# POLICY (2026-09-23): kbs-data targets an EXTERNAL (GitHub) remote, so its tree
# and history must stay free of org/SPC-specific data. This script ALWAYS commits
# LOCALLY (nothing is lost), but only pushes to the external `origin` when
# KBS_ALLOW_EXTERNAL_PUSH=1 is explicitly set (e.g. in ~/.bashrc or an env file).
# Default is commit-only — no external push.
#
# Generous cron: @reboot + 12:45,16:45 (laptop up ~8-10h/day; 23:45 was missed).
#
# Auth: repo-local credential helper (scripts/git-credential-env.sh) serves
# GITHUB_TOKEN from the git-ignored .env — no interactive login needed.
# Local run log: ~/kbs/backup.log (git-ignored via *.log).

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

TS="$(date '+%Y-%m-%d %H:%M:%S')"
LOG="$ROOT/backup.log"

# Ensure the portable credential helper is configured (survives fresh clones)
if [ "$(git config credential.helper)" != "!bash scripts/git-credential-env.sh" ]; then
    git config credential.helper '!bash scripts/git-credential-env.sh'
fi

git add -A

if git diff --cached --quiet; then
    echo "[$TS] BACKUP | no changes" >> "$LOG"
    exit 0
fi

SUMMARY="$(git diff --cached --stat | tail -1 | sed 's/^ *//')"
git commit -q -m "Nightly backup $(date '+%Y-%m-%d')

$SUMMARY"

# Commit-only unless external push explicitly allowed.
if [ "${KBS_ALLOW_EXTERNAL_PUSH:-0}" != "1" ]; then
    echo "[$TS] BACKUP | committed locally (external push disabled; KBS_ALLOW_EXTERNAL_PUSH not set) | $SUMMARY" >> "$LOG"
    exit 0
fi

if git push -q origin master 2>> "$LOG"; then
    echo "[$TS] BACKUP | pushed | $SUMMARY" >> "$LOG"
else
    echo "[$TS] BACKUP | PUSH FAILED | $SUMMARY" >> "$LOG"
    exit 1
fi