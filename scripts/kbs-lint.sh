#!/usr/bin/env bash
# kbs-lint.sh — deterministic shape validator for KBS owner-data files.
#
# WHY THIS EXISTS
#   Correctness of KBS artefacts currently depends on the *model* noticing its own
#   output is malformed — a latent skill that differs between models (e.g. DeepSeek
#   vs GLM). This script moves shape-correctness out of the model and into a check
#   the model runs: "write, then lint, then fix what it reports." Any model that can
#   follow a fix-list can produce conforming entries. No LLM, no network.
#
# USAGE
#   scripts/kbs-lint.sh [instance_dir]        # defaults to $KBS or ~/kbs
#   scripts/kbs-lint.sh --quiet ~/kbs         # only print on problems
#   scripts/kbs-lint.sh --json  ~/kbs         # machine-readable summary
#
# EXIT: 0 = clean, 1 = problems found, 2 = usage/env error.
#
# STRUCTURE RULE (applies to ACTIONS/DECISIONS/FAILURES/SUCCESSES):
#   A '## ' heading is an ENTRY only if it begins with a date (YYYY-MM-DD | … or
#   'YYYY-MM-DD: …'). Any other '## ' heading is a SECTION and is skipped. This is
#   the reliable discriminator; section names are free text and not enumerable.
#
# FIELD RULE: fields are INLINE — '**Field:** value' on one line. A field with an
#   empty value after the marker is reported (except where noted optional).
#
# Installer seed rows (20XX-… dates) are INFO, never failures.

set -uo pipefail

QUIET=0
JSON=0
INSTANCE=""

for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
    --json)     JSON=1 ;;
    -h|--help)  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         echo "unknown flag: $arg" >&2; exit 2 ;;
    *)          INSTANCE="$arg" ;;
  esac
done

INSTANCE="${INSTANCE:-${KBS:-$HOME/kbs}}"
if [ ! -d "$INSTANCE" ]; then
  echo "ERROR: instance dir not found: $INSTANCE" >&2
  exit 2
fi

PROBLEMS=0
INFOS=0
declare -a FINDINGS=()

finding() { # level file line message
  if [ "$1" = "ERROR" ]; then PROBLEMS=$((PROBLEMS+1)); else INFOS=$((INFOS+1)); fi
  FINDINGS+=("$1|$2|$3|$4")
}

is_seed_date() { printf '%s' "$1" | grep -qE '^20XX-'; }
valid_date()   { printf '%s' "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; }
TODAY="$(date +%Y-%m-%d)"

# emit "lineno<TAB>heading" for entry headings only (date-prefixed), skipping
# fenced code blocks and <!-- EXAMPLE --> regions (those are documentation).
entry_headings() { # file
  awk '
    /^```/ { fence=!fence; next }
    /<!-- *EXAMPLE/ { inexample=1; next }
    /<!-- *END EXAMPLE/ { inexample=0; next }
    fence || inexample { next }
    /^## / {
      h=$0; sub(/^## /,"",h)
      if (h ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]*[|:]/ || h ~ /^20XX-/) print NR"\t"h
    }
  ' "$1"
}

# inline value of '**Field:**' on a given line (trimmed); empty if absent/blank
inline_value() { # file lineno field_label
  awk -v s="$2" -v lab="$3" 'NR==s{ needle="**" lab ":**"; if(index($0,needle)){ v=$0; sub(/^.*\*\*[^*]*\*\*[[:space:]]*/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); print v } }' "$1"
}

# does a field label appear anywhere in the entry block [start,end)?
block_has_field() { # file start end label
  awk -v s="$2" -v e="$3" -v lab="$4" 'NR>s && (e==0 || NR<=e) { if(/^## /) exit; needle="**" lab ":**"; if(index($0,needle)){found=1; exit} } END{exit (found?0:1)}' "$1"
}

# line number of a field label within the block
line_of_field() { # file start label
  awk -v s="$2" -v lab="$3" 'NR>s{ if(/^## /) exit; needle="**" lab ":**"; if(index($0,needle)){print NR; exit} }' "$1"
}

# ── ACTIONS.md ───────────────────────────────────────────────────────────────
lint_actions() {
  local f="$INSTANCE/ACTIONS.md"
  [ -f "$f" ] || return 0
  local total; total="$(wc -l < "$f")"
  local ln heading
  while IFS=$'\t' read -r ln heading; do
    local title="$heading" d="${heading%% |*}"
    # locate end of block for boundary-aware field search
    local end; end="$(awk -v s="$ln" 'NR>s && /^## /{print NR-1; exit}' "$f")"
    [ -z "$end" ] && end="$total"

    if ! valid_date "$d" && ! is_seed_date "$d"; then
      finding ERROR ACTIONS.md "$ln" "entry heading lacks a YYYY-MM-DD prefix: ${title:0:60}"
    fi
    local fld
    for fld in Decided Why Due Done; do
      if ! block_has_field "$f" "$ln" "$end" "$fld"; then
        finding ERROR ACTIONS.md "$ln" "missing **$fld:** (${title:0:50})"
      fi
    done

    if is_seed_date "$d"; then
      finding INFO ACTIONS.md "$ln" "installer seed row (20XX date) — retire with 'Done: N/A — installer seed example'"
      continue
    fi

    local doneln doneval
    doneln="$(line_of_field "$f" "$ln" "Done")"
    doneval="$(inline_value "$f" "$doneln" "Done")"
    if printf '%s' "$doneval" | grep -qiE '^[[:space:]]*(No|N/A)?[[:space:]]*$'; then
      # open action — overdue?
      local duel dueval
      duel="$(line_of_field "$f" "$ln" "Due")"
      dueval="$(inline_value "$f" "$duel" "Due")"
      if valid_date "$dueval" && [ "$dueval" \< "$TODAY" ]; then
        finding ERROR ACTIONS.md "$duel" "OVERDUE open action (Due $dueval, today $TODAY): ${title:0:50}"
      fi
    else
      # completed — Outcome must be present and non-empty
      if ! block_has_field "$f" "$ln" "$end" "Outcome"; then
        finding ERROR ACTIONS.md "$ln" "Done is set but no **Outcome:** field: ${title:0:50}"
      else
        local oln oval
        oln="$(line_of_field "$f" "$ln" "Outcome")"
        oval="$(inline_value "$f" "$oln" "Outcome")"
        [ -z "$oval" ] && finding ERROR ACTIONS.md "$oln" "Done is set but **Outcome:** is empty: ${title:0:50}"
      fi
    fi
  done < <(entry_headings "$f")
}

# ── DECISIONS.md ─────────────────────────────────────────────────────────────
lint_decisions() {
  local f="$INSTANCE/DECISIONS.md"
  [ -f "$f" ] || return 0
  local ln heading
  while IFS=$'\t' read -r ln heading; do
    local d="${heading%%:*}"
    if ! valid_date "$d"; then
      finding ERROR DECISIONS.md "$ln" "heading must be '## YYYY-MM-DD: <decision>': ${heading:0:60}"
    fi
    local nb
    nb="$(awk -v s="$ln" 'NR>s && NF>0 {print; exit}' "$f")"
    if [ -z "$nb" ] || [ "${nb:0:2}" = "##" ]; then
      finding ERROR DECISIONS.md "$ln" "decision has no body text: ${heading:0:50}"
    fi
  done < <(entry_headings "$f")
}

# ── FAILURES.md / SUCCESSES.md ───────────────────────────────────────────────
# required fields are a '|'-separated list so labels containing spaces work.
lint_fs() { # filename  required_pipe_sep  seed_ok
  local fname="$1" required="$2" f="$INSTANCE/$1"
  [ -f "$f" ] || return 0
  local total; total="$(wc -l < "$f")"
  local ln heading
  while IFS=$'\t' read -r ln heading; do
    local d="${heading%% |*}"
    local end; end="$(awk -v s="$ln" 'NR>s && /^## /{print NR-1; exit}' "$f")"
    [ -z "$end" ] && end="$total"
    if ! valid_date "$d" && ! is_seed_date "$d"; then
      finding ERROR "$fname" "$ln" "entry heading lacks a YYYY-MM-DD prefix: ${heading:0:60}"
    fi
    if is_seed_date "$d"; then
      finding INFO "$fname" "$ln" "installer seed row (20XX date)"
      continue
    fi
    local req
    while IFS= read -r req; do
      [ -z "$req" ] && continue
      if ! block_has_field "$f" "$ln" "$end" "$req"; then
        finding ERROR "$fname" "$ln" "missing **$req:** (${heading:0:45})"
      fi
    done < <(printf '%s' "$required" | tr '|' '\n')
  done < <(entry_headings "$f")
}

# ── INBOX.md / CHAT_INBOX.md timestamps ──────────────────────────────────────
lint_inbox() {
  local fname="$1" f="$INSTANCE/$1"
  [ -f "$f" ] || return 0
  local bounds s e
  bounds="$(awk '
    /^## Unprocessed/ {insec=1; start=NR; next}
    insec && /^## / {print start, NR-1; exit}
    insec {last=NR}
    END{if(insec) print start,(last?last:NR)}
  ' "$f")"
  [ -z "$bounds" ] && return 0
  read -r s e <<<"$bounds"
  [ -z "${s:-}" ] && return 0
  local ln heading
  while IFS=$'\t' read -r ln heading; do
    if ! printf '%s' "$heading" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}:[0-9]{2}'; then
      finding ERROR "$fname" "$ln" "unprocessed entry heading has no date/time: ${heading:0:60}"
    fi
  done < <(awk -v s="$s" -v e="$e" 'NR>s && NR<=e && /^### / || /^#### / {print NR"\t"$0}' "$f")
}

lint_actions
lint_decisions
lint_fs FAILURES.md  "What failed|Root cause|Expected vs actual|Lesson|Resolved" 1
lint_fs SUCCESSES.md "What worked|Lesson|Expected vs actual" 1
lint_inbox INBOX.md
lint_inbox CHAT_INBOX.md

# ── report ───────────────────────────────────────────────────────────────────
if [ "$JSON" -eq 1 ]; then
  printf '{"instance":"%s","errors":%d,"infos":%d,"findings":[' "$INSTANCE" "$PROBLEMS" "$INFOS"
  first=1
  for x in "${FINDINGS[@]:-}"; do
    [ -z "$x" ] && continue
    IFS='|' read -r lv fl lnl msg <<<"$x"
    [ "$first" -eq 0 ] && printf ','
    first=0
    printf '{"level":"%s","file":"%s","line":%s,"message":"%s"}' "$lv" "$fl" "$lnl" "$(printf '%s' "$msg" | sed 's/"/\\"/g')"
  done
  printf ']}\n'
else
  for x in "${FINDINGS[@]:-}"; do
    [ -z "$x" ] && continue
    IFS='|' read -r lv fl lnl msg <<<"$x"
    printf '%-5s %s:%s  %s\n' "$lv" "$fl" "$lnl" "$msg"
  done
  if [ "$QUIET" -eq 0 ] || [ "$PROBLEMS" -gt 0 ]; then
    echo
    echo "kbs-lint: $PROBLEMS error(s), $INFOS info  [$INSTANCE]"
    [ "$PROBLEMS" -eq 0 ] && echo "OK — owner-data shapes conform."
  fi
fi

[ "$PROBLEMS" -eq 0 ] && exit 0 || exit 1
