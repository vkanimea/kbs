#!/bin/bash
# KBS Drift Check — daily guard against system-file drift. V0.116.3
# Schedule (daily): 15 9 * * * ~/kbs/scripts/kbs-drift-check.sh
#
# The system repo is the source of truth for system files; a data instance holds
# an installed copy. This wrapper runs `kbs-sync.sh --check` against the system
# repo and records drift to log.md — and ONLY logs when there is drift, so a
# healthy instance stays quiet (matching hourly-ingest.sh's no-noise behaviour).
#
# Exit codes: 0 = in sync (or system repo unavailable), 1 = drift detected.
#
# Config (env or ~/.env):
#   KBS_PATH        data instance            (default: ~/kbs)
#   KBS_SYSTEM_REPO system repo checkout     (default: ~/AIC/kbs)
#   KBS_KB_NAME     KB label for the log     (default: main)

set -euo pipefail

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KBS_KB_NAME:-${KB_NAME:-main}}"
SYSTEM_REPO="${KBS_SYSTEM_REPO:-$HOME/AIC/kbs}"
LOG="$KBS_PATH/log.md"
SYNC="$KBS_PATH/scripts/kbs-sync.sh"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Missing pieces are not drift — they mean the guard cannot run. Say so once,
# quietly, and exit 0 so cron does not mail on every run.
if [ ! -x "$SYNC" ] && [ ! -f "$SYNC" ]; then
  echo "[$TIMESTAMP] DRIFT_CHECK | $KB_NAME | skipped — kbs-sync.sh not found in $KBS_PATH/scripts" >> "$LOG"
  exit 0
fi
if [ ! -d "$SYSTEM_REPO" ]; then
  echo "[$TIMESTAMP] DRIFT_CHECK | $KB_NAME | skipped — system repo not found at $SYSTEM_REPO" >> "$LOG"
  exit 0
fi

# --check prints the offending files and exits non-zero on drift.
if OUTPUT="$(bash "$SYNC" --from "$SYSTEM_REPO" --to "$KBS_PATH" --check 2>&1)"; then
  # In sync — stay quiet. (Uncomment to log every run instead.)
  # echo "[$TIMESTAMP] DRIFT_CHECK | $KB_NAME | in sync" >> "$LOG"
  exit 0
fi

# Drift: summarise the changed paths into one log line.
FILES=$(printf '%s\n' "$OUTPUT" | sed -n 's/^ *\(update\|add\): *//p' | paste -sd ', ' -)
[ -z "$FILES" ] && FILES="(unparsed — see output)"
echo "[$TIMESTAMP] DRIFT_CHECK | $KB_NAME | DRIFT vs system repo: $FILES (run scripts/kbs-sync.sh)" >> "$LOG"

# Notify on desktop where available, so drift is seen before it compounds.
MSG="KBS drift detected: system files differ from the system repo. Run kbs-sync.sh."
if command -v notify-send &>/dev/null; then
  notify-send "Knowledge Base System" "$MSG" 2>/dev/null || true
fi

exit 1
