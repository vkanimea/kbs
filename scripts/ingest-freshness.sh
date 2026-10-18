#!/usr/bin/env bash
# ingest-freshness.sh — connector watchdog: detect SILENT ingest stops.
#
# WHY THIS EXISTS (2026-10-19, V0.128)
# Connectors die quietly: API keys rotate, permissions change, routes stop
# existing, an upgrade removes a cron line. A knowledge base that stops
# receiving data is MORE dangerous than one you know is broken, because
# retrieval keeps answering confidently from stale truth. (The kbs-raw backup
# path learned this the hard way in 2026-10-12: three missed days behind a
# healthy-looking cron. backup-catchup.sh + backup-verify.sh already close
# that gap for backups; this script does the same for the ingest connectors.)
#
# WHAT IT CHECKS (derived from artefacts — no new stamp files, no connector edits)
#   1. log.md         last HOURLY_INGEST line  — cron alive?
#   2. backup.log     last timestamped line    — backup catchup alive?
#   3. $HOME/.local/state/kbs-backup/*.last   — each catchup job within its interval?
#   4. INBOX.md / CHAT_INBOX.md  last capture  — INFO only (captures are human-paced)
#
# USAGE
#   scripts/ingest-freshness.sh [instance]        # defaults to $KBS or ~/kbs
#   --max-ingest-age HOURS   (default 36)   hourly cron: allow one missed hour + slack
#   --max-backup-age HOURS   (default 48)   daily backup: allow one missed day + slack
#   --max-capture-days  DAYS (default 30)   INFO-level only
#
# EXIT: 0 = fresh, 1 = any WARN, 2 = usage/env error.

set -uo pipefail

INSTANCE=""
MAX_INGEST_AGE=36
MAX_BACKUP_AGE=48
MAX_CAPTURE_DAYS=30

while [ $# -gt 0 ]; do
  case "$1" in
    --max-ingest-age)   MAX_INGEST_AGE="${2:?}"; shift 2 ;;
    --max-backup-age)   MAX_BACKUP_AGE="${2:?}"; shift 2 ;;
    --max-capture-days) MAX_CAPTURE_DAYS="${2:?}"; shift 2 ;;
    -h|--help) sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  INSTANCE="$1"; shift ;;
  esac
done

INSTANCE="${INSTANCE:-${KBS:-$HOME/kbs}}"
if [ ! -d "$INSTANCE" ]; then
  echo "ERROR: instance dir not found: $INSTANCE" >&2
  exit 2
fi

NOW="$(date +%s)"
WARNS=0
INFOS=0

age_hours() { # epoch -> integer hours since then
  echo $(( (NOW - $1) / 3600 ))
}

WARN() { WARNS=$((WARNS+1)); printf 'WARN   %s\n' "$1"; }
INFO() { INFOS=$((INFOS+1)); printf 'INFO   %s\n' "$1"; }
OK()   { printf 'OK     %s\n' "$1"; }

# "[YYYY-MM-DD HH:MM:SS]" epoch of the LAST matching line in file, or empty
last_ts_epoch() { # file grep-pattern
  local ts
  ts="$(grep -F "$2" "$1" 2>/dev/null | tail -1 | grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]' | tr -d '[]' || true)"
  [ -z "$ts" ] && return 1
  date -d "$ts" +%s 2>/dev/null || return 1
}

echo "ingest-freshness: $INSTANCE  ($(date '+%Y-%m-%d %H:%M'))"
echo

# ── 1. hourly ingest cron ────────────────────────────────────────────────────
if [ -f "$INSTANCE/log.md" ]; then
  if E="$(last_ts_epoch "$INSTANCE/log.md" "HOURLY_INGEST")"; then
    A="$(age_hours "$E")"
    if [ "$A" -le "$MAX_INGEST_AGE" ]; then
      OK "hourly ingest: last run ${A}h ago (threshold ${MAX_INGEST_AGE}h)"
    else
      WARN "hourly ingest: last run ${A}h ago (threshold ${MAX_INGEST_AGE}h) — cron dead or host asleep?"
    fi
  else
    WARN "hourly ingest: no HOURLY_INGEST line in log.md at all — connector never ran or log was reset"
  fi
else
  WARN "log.md missing in $INSTANCE"
fi

# ── 2. backup log ────────────────────────────────────────────────────────────
if [ -f "$INSTANCE/backup.log" ]; then
  if E="$(last_ts_epoch "$INSTANCE/backup.log" "")"; then
    A="$(age_hours "$E")"
    if [ "$A" -le "$MAX_BACKUP_AGE" ]; then
      OK "backups: last backup.log line ${A}h ago (threshold ${MAX_BACKUP_AGE}h)"
    else
      WARN "backups: last backup.log line ${A}h ago (threshold ${MAX_BACKUP_AGE}h) — catchup wrapper not running?"
    fi
  else
    WARN "backup.log has no timestamped lines — format drift?"
  fi
else
  INFO "backup.log not present (backup logging may live elsewhere)"
fi

# ── 3. per-job catchup stamps ────────────────────────────────────────────────
STATE_DIR="${KBS_CATCHUP_STATE:-$HOME/.local/state/kbs-backup}"
if [ -d "$STATE_DIR" ]; then
  for stamp in "$STATE_DIR"/*.last; do
    [ -f "$stamp" ] || continue
    job="$(basename "$stamp" .last)"
    epoch="$(cat "$stamp" 2>/dev/null || echo 0)"
    case "$epoch" in ''|*[!0-9]*) WARN "catchup job '$job': unreadable stamp"; continue ;; esac
    A="$(age_hours "$epoch")"
    if [ "$A" -le "$MAX_BACKUP_AGE" ]; then
      OK "catchup job '$job': last success ${A}h ago"
    else
      WARN "catchup job '$job': last success ${A}h ago — job failing or not invoked"
    fi
  done
else
  INFO "no catchup state dir ($STATE_DIR) — backup-catchup.sh not in use here"
fi

# ── 4. capture activity (INFO only — humans do not capture on a cron) ────────
for f in INBOX.md CHAT_INBOX.md; do
  [ -f "$INSTANCE/$f" ] || continue
  # newest '### YYYY-MM-DD …' heading — sort so ordering in the file does not matter
  d="$(grep -oE '^### [0-9]{4}-[0-9]{2}-[0-9]{2}' "$INSTANCE/$f" 2>/dev/null | awk '{print $2}' | sort -u | tail -1 || true)"
  if [ -n "$d" ]; then
    DAYS=$(( (NOW - $(date -d "$d" +%s 2>/dev/null || echo "$NOW")) / 86400 ))
    if [ "$DAYS" -gt "$MAX_CAPTURE_DAYS" ]; then
      INFO "$f: last capture ${DAYS}d ago (>${MAX_CAPTURE_DAYS}d) — is capture still wired?"
    else
      OK "$f: last capture ${DAYS}d ago"
    fi
  fi
done

echo
if [ "$WARNS" -gt 0 ]; then
  echo "ingest-freshness: $WARNS WARN(s), $INFOS info — a connector has stopped producing; a KB answering from stale truth is the failure mode this prevents."
  exit 1
fi
echo "ingest-freshness: all connectors fresh ($INFOS info)."
exit 0
