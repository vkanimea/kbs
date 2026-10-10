#!/usr/bin/env bash
# kbs-provenance.sh — content-side check for FABRICATED DATES in a *proposed* entry.
#
# kbs-lint.sh checks SHAPE (fields, headings). It cannot see whether a value is true.
# This covers the one content gap an acceptance test exposed (2026-10-11): when the
# input supplies no date, models fabricate a heading date, defaulting to a training-era
# value (2023-2024). Date fabrication is a GENERIC LLM behaviour, measured at ~50% across
# all four models tested (GLM-4.7, DeepSeek-v3.1, Llama-3.1-8B, Qwen-2.5-7B). An earlier,
# smaller sample suggested GLM fabricated 3x more than DeepSeek; that did NOT replicate
# and is retracted. Do not cite it. See maintenance/20261011-p-kbs-session-probe.
#
# KEY DESIGN POINT: provenance can only be judged against the INPUT. Checking an
# instance after the fact is meaningless — legitimate entries contain many historic
# dates (the real ~/kbs instance yields 92 false positives). So this tool checks ONE
# proposed entry against the dates that actually appeared in the source text:
#
#   scripts/kbs-provenance.sh --source <input.txt> --entry <proposed-entry.md>
#   scripts/kbs-provenance.sh --source <input.txt> --entry -      # entry on stdin
#
# Intended use in the write loop:
#   1. model drafts the entry
#   2. echo "$draft" | scripts/kbs-provenance.sh --source "$owner_input" --entry -
#   3. model fixes any flagged date (use a supplied value, or today, or ask)
#
# A date in the entry is GROUNDED if it is:
#   - present anywhere in the source text, or
#   - today's date, or
#   - ≤8 days before today (a legitimate recent Done date), or
#   - a 20XX installer placeholder.
# Otherwise it is UNGROUNDED = fabricated.
#
# EXIT: 0 = grounded, 1 = fabricated date(s), 2 = usage error.

set -uo pipefail

SRC=""; ENTRY=""; TODAY="$(date +%Y-%m-%d)"

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="$2"; shift 2 ;;
    --entry)  ENTRY="$2"; shift 2 ;;
    --today)  TODAY="$2"; shift 2 ;;
    -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$SRC" ]   || { echo "ERROR: --source <input text> required" >&2; exit 2; }
[ -n "$ENTRY" ] || { echo "ERROR: --entry <file|-> required" >&2; exit 2; }
[ -f "$SRC" ]   || { echo "ERROR: source not found: $SRC" >&2; exit 2; }

if [ "$ENTRY" = "-" ]; then
  ENTRY_TEXT="$(cat)"
else
  [ -f "$ENTRY" ] || { echo "ERROR: entry not found: $ENTRY" >&2; exit 2; }
  ENTRY_TEXT="$(cat "$ENTRY")"
fi

# dates supplied by the input
SRC_DATES="$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$SRC" | sort -u | tr '\n' ' ')"
CUTOFF="$(date -d "$TODAY - 8 days" +%Y-%m-%d 2>/dev/null || echo "$TODAY")"

grounded() { # date
  local d="$1"
  case "$d" in 20XX-*) return 0 ;; esac
  [ "$d" = "$TODAY" ] && return 0
  [ "$d" \> "$CUTOFF" ] && return 0   # recent past
  case " $SRC_DATES " in *" $d "*) return 0 ;; esac
  return 1
}

FAB=0
ln=0
while IFS= read -r line; do
  ln=$((ln+1))
  for d in $(printf '%s' "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}'); do
    if ! grounded "$d"; then
      FAB=$((FAB+1))
      printf 'FABRICATED date %s at line %s — not in source, not today (%s), not recent\n' "$d" "$ln" "$TODAY"
      printf '   | %s\n' "$(printf '%s' "$line" | cut -c1-78)"
    fi
  done
done <<< "$ENTRY_TEXT"

if [ "$FAB" -eq 0 ]; then
  echo "kbs-provenance: OK — every date is grounded (source dates: ${SRC_DATES:-none})"
  exit 0
else
  echo
  echo "kbs-provenance: $FAB fabricated date(s). A date not present in the input is invented."
  echo "Fix: use a date from the input, today ($TODAY), or ask the owner. Never default to a training-era date."
  exit 1
fi
