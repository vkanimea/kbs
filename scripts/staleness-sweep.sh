#!/usr/bin/env bash
# staleness-sweep.sh — REPORT entries past their shelf life. NEVER modifies.
#
# WHY THIS EXISTS (2026-10-19, V0.128)
# Recency weighting (CONVENTIONS §8) is only half the mechanism: something must
# periodically surface entries carrying facts that decay — prices, model IDs,
# versions, quotas, credentials, schedules. Retrieval prefers the recent, but a
# stale entry that is never reviewed stays a confident wrong answer forever.
#
# Provenance posture: this script NEVER deletes or rewrites. It lists candidates;
# marking/reviewing is the owner's decision. (Sister tool: kbs-provenance.sh,
# which checks dates for fabrication; this one checks them for AGE.)
#
# WHAT IT SCANS
#   DECISIONS.md, FAILURES.md, SUCCESSES.md, JOURNAL.md, wiki topics.
#   Two independent signals:
#     1. AGE      — date-prefixed entry older than --days (default 180).
#     2. VOLATILE — entry older than threshold AND containing a decaying-fact
#                   token (model id, version string, price, quota, credential).
#
# USAGE
#   scripts/staleness-sweep.sh [instance]      # defaults to $KBS or ~/kbs
#   --days N       shelf life in days (default 180)
#   --strict       exit 1 if any candidate found (for cron alerting)
#
# EXIT: 0 = report produced, 1 = candidates found AND --strict, 2 = usage error.

set -uo pipefail

INSTANCE=""
DAYS=180
STRICT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --days)   DAYS="${2:?}"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
CANDIDATES=0

# tokens whose meaning decays with time; an old entry containing one deserves review
VOLATILE_RE='deepseek/|anthropic/|openai/|google/|glm-|gpt-[0-9]|claude-[0-9]|V[0-9]+\.[0-9]+|v[0-9]+\.[0-9]+|\$[0-9]|price|quota|credential|API key|api_key'

sweep_file() { # relative-path
  local rel="$1" f="$INSTANCE/$1"
  [ -f "$f" ] || return 0
  # date-prefixed entry headings: '## YYYY-MM-DD …' or '### YYYY-MM-DD …'
  grep -nE '^#{2,3} [0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" 2>/dev/null | while IFS= read -r line; do
    ln="${line%%:*}"
    hd="${line#*: }"
    d="$(printf '%s' "$hd" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
    [ -z "$d" ] && continue
    e="$(date -d "$d" +%s 2>/dev/null || continue)"
    age=$(( (NOW - e) / 86400 ))
    [ "$age" -le "$DAYS" ] && continue
    if sed -n "${ln},$((ln+40))p" "$f" | grep -qiE "$VOLATILE_RE"; then
      printf 'REVIEW %s:%s  [%sd old, volatile facts]  %s\n' "$rel" "$ln" "$age" "${hd:0:70}"
    else
      printf 'age    %s:%s  [%sd old]  %s\n' "$rel" "$ln" "$age" "${hd:0:70}"
    fi
  done
}

echo "staleness-sweep: $INSTANCE  (shelf life ${DAYS}d, $(date '+%Y-%m-%d'))"
echo

REPORT=""
for f in DECISIONS.md FAILURES.md SUCCESSES.md JOURNAL.md; do
  REPORT+="$(sweep_file "$f")"
done
# wiki topics sweep
if [ -d "$INSTANCE/kb/main/wiki/topics" ]; then
  while IFS= read -r tf; do
    REPORT+="$(sweep_file "kb/main/wiki/topics/$(basename "$tf")")"
  done < <(find "$INSTANCE/kb/main/wiki/topics" -name '*.md' -type f 2>/dev/null | sort)
fi

if [ -n "$REPORT" ]; then
  echo "$REPORT" | sed '/^$/d'
  CANDIDATES="$(echo "$REPORT" | sed '/^$/d' | wc -l | tr -d ' ')"
  echo
  echo "staleness-sweep: $CANDIDATES candidate(s) past ${DAYS}d. REVIEW, do not bulk-delete — confirm current, mark '**Superseded by:**', or annotate. Nothing was modified."
  [ "$STRICT" -eq 1 ] && exit 1
  exit 0
fi

echo "staleness-sweep: no entries past ${DAYS}d. Nothing to review."
exit 0
