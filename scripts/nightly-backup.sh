#!/bin/bash
# KBS Nightly Backup — commit + push your KBS data repo to its git remote if anything changed.
# Schedule: 45 23 * * * ~/kbs/scripts/nightly-backup.sh
#
# Auth: repo-local credential helper (scripts/git-credential-env.sh) serves
# GITHUB_TOKEN from the git-ignored .env — no interactive login needed.
# Local run log: <repo>/backup.log (git-ignored via *.log).
#
# Setup:
#   1. Create a PRIVATE remote repo for your KBS data (it contains your knowledge —
#      keep it private) and add it as origin.
#   2. cp .env.template .env and add GITHUB_TOKEN (write-capable).
#   3. git config credential.helper '!bash scripts/git-credential-env.sh'
#   4. Add the cron entry above.

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

if git push -q origin HEAD 2>> "$LOG"; then
    echo "[$TS] BACKUP | pushed | $SUMMARY" >> "$LOG"
else
    echo "[$TS] BACKUP | PUSH FAILED | $SUMMARY" >> "$LOG"
    exit 1
fi
