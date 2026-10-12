#!/bin/bash
# backup-catchup.sh — run a periodic backup job only if it is OVERDUE.
#
# WHY THIS EXISTS (2026-10-12):
# The laptop is not a 24x7 host. The daily backups were armed at fixed clock
# times (13:30 openviking, 13:45 pi-state). If the machine was asleep at that
# minute, cron skipped the job entirely — no backlog, no retry. Observed: the
# openviking and pi-state backups did not run for 3 days (last 2026-10-09
# 16:15) because the laptop was asleep at 13:30-13:45; hourly jobs kept firing
# so cron looked healthy. Meanwhile sessions grew 137 -> 172 with no offsite
# copy.
#
# This is the same failure shape as the MQTT subscriber (monitoring the
# producer, not the consumer) and the nightly-backup.sh guard bug: a green
# schedule that is not actually protecting anything.
#
# THE FIX: invert the question. Instead of "is it 13:30?", ask "has this job
# succeeded within its interval?". A wrapper invoked HOURLY (which survives
# wake/reboot far better than a once-daily trigger) runs the job only when the
# stamp is older than the interval, then records success. Missed windows
# self-heal on the next wake; repeat invocations are cheap no-ops.
#
# Usage:  backup-catchup.sh <job-name> <interval-hours> <command...>
# State:  $HOME/.local/state/kbs-backup/<job-name>.last  (unix epoch of last OK)
# Env:    KBS_CATCHUP_DRYRUN=1  -> report the decision, run nothing
#         KBS_CATCHUP_FORCE=1   -> ignore the stamp and run regardless

set -u
NAME="${1:-}"; INTERVAL_H="${2:-}"; shift 2 2>/dev/null || true

if [ -z "$NAME" ] || [ -z "$INTERVAL_H" ] || [ "$#" -eq 0 ]; then
    echo "usage: backup-catchup.sh <job-name> <interval-hours> <command...>" >&2
    exit 2
fi

LOG_HOME="${KBS_LOG_HOME:-$HOME/kbs}"
LOG="$LOG_HOME/backup.log"
STATE_DIR="${KBS_CATCHUP_STATE:-$HOME/.local/state/kbs-backup}"
STAMP="$STATE_DIR/$NAME.last"
mkdir -p "$STATE_DIR"

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] BACKUP_CATCHUP | $*" >> "$LOG" 2>/dev/null || true; }

NOW="$(date +%s)"
INTERVAL_S=$(( INTERVAL_H * 3600 ))
LAST=0
[ -f "$STAMP" ] && LAST="$(cat "$STAMP" 2>/dev/null || echo 0)"
case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac

if [ "${KBS_CATCHUP_FORCE:-0}" = "1" ]; then
    DUE=1; REASON="forced (KBS_CATCHUP_FORCE=1)"
elif [ "$LAST" -eq 0 ]; then
    DUE=1; REASON="no prior success recorded"
else
    AGE=$(( NOW - LAST ))
    if [ "$AGE" -ge "$INTERVAL_S" ]; then
        DUE=1; REASON="overdue (age ${AGE}s >= ${INTERVAL_S}s)"
    else
        DUE=0; REASON="fresh (age ${AGE}s < ${INTERVAL_S}s)"
    fi
fi

if [ "${KBS_CATCHUP_DRYRUN:-0}" = "1" ]; then
    echo "DRYRUN $NAME: $([ "$DUE" -eq 1 ] && echo RUN || echo SKIP) — $REASON"
    exit 0
fi

if [ "$DUE" -eq 0 ]; then
    exit 0
fi

# Run the job. Only a zero exit records success, so a failing backup stays
# overdue and is retried on the next hourly tick instead of being forgotten.
if "$@"; then
    date +%s > "$STAMP"
    log "$NAME | ran and recorded success — $REASON"
    exit 0
else
    rc=$?
    log "$NAME | FAILED (exit $rc) — stamp NOT updated, will retry — $REASON"
    echo "ERR backup-catchup: $NAME failed (exit $rc)" >&2
    exit "$rc"
fi