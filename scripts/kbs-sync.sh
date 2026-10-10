#!/bin/bash
# KBS Sync — refresh a data instance's system files from the system repo. V0.116
#
# The system repo (this repo) is the source of truth for system files. A data
# instance (~/kbs / kbs-data) contains knowledge PLUS an installed copy of those
# system files. This script re-syncs that copy, so the two never drift.
#
# Why this exists: fixes made directly in a data instance fork the system. The
# rule is "fix upstream, sync down" — this script is the "sync down" half.
#
# Usage:
#   kbs-sync.sh [--from <system-repo-dir>] [--to <data-dir>] [--dry-run] [--check]
#
#   --from <dir>   system repo checkout to sync FROM (default: this script's repo)
#   --to <dir>     data instance to sync TO (default: $KBS or ~/kbs)
#   --dry-run      print what would change, copy nothing
#   --check        exit 1 if any system file differs (CI / pre-flight use)
#
# Contract (mirrors install.sh):
#   SYSTEM-owned  -> always overwritten (docs/, scripts/, CHANGELOG.md, VERSION,
#                    agents.md, PROMPTS.md, reference/)
#   USER-owned    -> NEVER touched (INBOX, CHAT_INBOX, DECISIONS, FAILURES,
#                    SUCCESSES, ACTIONS, JOURNAL, CAREER, SYSTEM, log.md)
#   .gitignore    -> NEVER touched (seed-only; instances add their own rules)
#   .env.template -> generated per-instance by install.sh, not synced verbatim
#   templates/    -> included because agents.md / PROMPTS.md / reference/ come from there

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TO="${KBS:-$HOME/kbs}"

# The system repo is NEVER the instance. When this script is run from inside an
# instance (the normal case — it is installed there), $SCRIPT_DIR/.. is the DATA
# repo, not the system repo, so it must not be used as the default source.
# Resolution order for FROM:
#   1. --from <dir>                 (explicit)
#   2. $KBS_SYSTEM_REPO             (env)
#   3. a sibling checkout of the system repo, discovered by looking for VERSION
#      plus a scripts/kbs-sync.sh at the usual locations
FROM=""
for cand in "${KBS_SYSTEM_REPO:-}" "$HOME/AIC/kbs" "$HOME/kbs-system" "$(cd "$SCRIPT_DIR/.." && pwd)"; do
  [ -n "$cand" ] || continue
  if [ "$cand" != "$TO" ] && [ -f "$cand/install.sh" ] && [ -f "$cand/VERSION" ]; then
    FROM="$cand"
    break
  fi
done

DRY_RUN=0
CHECK=0

while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="${2:?--from needs a dir}"; shift 2 ;;
    --to)   TO="${2:?--to needs a dir}";   shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --check)   CHECK=1; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$FROM" ] || {
  echo "ERROR: could not locate the system repo. Pass --from <dir> or set KBS_SYSTEM_REPO." >&2
  echo "       Looked in: \$KBS_SYSTEM_REPO, ~/AIC/kbs, ~/kbs-system, $SCRIPT_DIR/.." >&2
  exit 2
}
[ "$FROM" != "$TO" ] || { echo "ERROR: system repo and instance are the same directory ($FROM)." >&2; exit 2; }
[ -d "$FROM" ] || { echo "ERROR: system repo not found: $FROM" >&2; exit 2; }
[ -d "$TO" ]   || { echo "ERROR: data instance not found: $TO" >&2; exit 2; }
[ -f "$FROM/install.sh" ] || { echo "ERROR: $FROM does not look like the system repo (no install.sh)" >&2; exit 2; }
[ -f "$FROM/VERSION" ] || { echo "ERROR: $FROM does not look like the system repo (no VERSION)" >&2; exit 2; }

# System-owned paths, relative to both repos. Mirrors install.sh's SYSTEM_TEMPLATES,
# REFERENCES, SCRIPTS, plus docs/ (which install.sh does not currently install).
# Entries as "src:dest" are sourced from templates/ in the system repo and land at
# dest in the instance (matching install.sh).
SYSTEM_PATHS=(
  templates/CONVENTIONS.md:CONVENTIONS.md
  templates/agents.md:agents.md
  templates/PROMPTS.md:PROMPTS.md
  CHANGELOG.md
  VERSION
  templates/reference/actions.md:reference/actions.md
  templates/reference/chat-input.md:reference/chat-input.md
  templates/reference/failures.md:reference/failures.md
  templates/reference/health-check.md:reference/health-check.md
  templates/reference/ingestion.md:reference/ingestion.md
  templates/reference/journal.md:reference/journal.md
  templates/reference/learning.md:reference/learning.md
  templates/reference/session-analysis.md:reference/session-analysis.md
  templates/reference/writing-style.md:reference/writing-style.md
  templates/reference/session-close.md:reference/session-close.md
  templates/reference/successes.md:reference/successes.md
  scripts/auto-close.sh
  scripts/analyze-sessions/sessions.py
  scripts/analyze-sessions/cost.py
  scripts/analyze-sessions/prompts.py
  scripts/analyze-sessions/search.py
  scripts/analyze-sessions/show_session.py
  scripts/analyze-sessions/README.md
  scripts/chat-adapter.sh
  scripts/chat-api-adapter.py
  scripts/due-actions.sh
  scripts/git-credential-env.sh
  scripts/goal-loop.sh
  scripts/graphify-index.sh
  scripts/health-check.sh
  scripts/hourly-ingest.sh
  scripts/kbs-drift-check.sh
  scripts/kbs-lint.sh
  scripts/model-config.sh
  scripts/nightly-backup.sh
  scripts/rag-index.sh
  scripts/rag-query.sh
  scripts/rag.py
  scripts/status.sh
  scripts/topic-index.sh
  scripts/windows/status.ps1
  scripts/youtube-ingest.sh
)

# docs/ is synced wholesale: it contains no user content.
while IFS= read -r f; do
  SYSTEM_PATHS+=("$f")
done < <(cd "$FROM" && find docs -name '*.md' -type f | sort)

changed=0
copied=0
missing_src=0
self_deferred=0

# Absolute path of the file bash is currently executing. Overwriting this file
# mid-run corrupts bash's incremental parse of it ("syntax error near unexpected
# token"): bash reads a script in chunks, so a changed file on disk yields a
# shifted/mixed region on the next read. We handle this by copying ourselves to a
# temp file and re-execing from there BEFORE any copy loop runs, so the file on
# disk is never the one being interpreted. (Fix for FAILURES.md 2026-10-06.)
SELF_REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
if [ "${KBS_SYNC_REEXEC:-0}" != "1" ] && [ "$DRY_RUN" -eq 0 ] && [ "$CHECK" -eq 0 ]; then
  _self_copy="$(mktemp "${TMPDIR:-/tmp}/kbs-sync-run.XXXXXX")"
  cp "$SELF_REAL" "$_self_copy"
  chmod +x "$_self_copy"
  KBS_SYNC_REEXEC=1 exec "$_self_copy" "$@"
fi

for rel in "${SYSTEM_PATHS[@]}"; do
  # "src:dest" — source from the system repo, land at dest in the instance.
  if [[ "$rel" == *:* ]]; then
    src_rel="${rel%%:*}"
    dst_rel="${rel#*:}"
  else
    src_rel="$rel"
    dst_rel="$rel"
  fi

  src="$FROM/$src_rel"
  dst="$TO/$dst_rel"

  if [ ! -f "$src" ]; then
    echo "  MISSING IN SYSTEM REPO: $src_rel" >&2
    missing_src=$((missing_src+1))
    continue
  fi

  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    continue
  fi

  changed=$((changed+1))
  is_self=0
  if [ -f "$dst" ] && [ "$(cd "$(dirname "$dst")" && pwd)/$(basename "$dst")" = "$SELF_REAL" ]; then
    is_self=1
  fi
  if [ "$is_self" -eq 0 ]; then
    if [ -f "$dst" ]; then
      echo "  update: $dst_rel"
    else
      echo "  add:    $dst_rel"
    fi
  fi

  if [ "$DRY_RUN" -eq 0 ] && [ "$CHECK" -eq 0 ]; then
    mkdir -p "$(dirname "$dst")"
    # Guard: the running script is a temp copy, but keep this for safety in case
    # re-exec did not happen (e.g. env override) — never cp over the running file.
    if [ "$is_self" -eq 1 ]; then
      self_deferred=1
      continue
    fi
    cp "$src" "$dst"
    copied=$((copied+1))
  fi
done

# Self-update fallback: only reached if re-exec was skipped. Safe to copy now.
if [ "$self_deferred" -eq 1 ]; then
  self_src="$FROM/scripts/kbs-sync.sh"
  if [ -f "$self_src" ]; then
    cp "$self_src" "$SELF_REAL"
    copied=$((copied+1))
    echo "  update: scripts/kbs-sync.sh (deferred self-update)"
  fi
fi

FROM_V="$(tr -d '[:space:]' < "$FROM/VERSION" 2>/dev/null || echo '?')"
TO_V="$(tr -d '[:space:]' < "$TO/VERSION" 2>/dev/null || echo '(none)')"

echo ""
if [ "$CHECK" -eq 1 ]; then
  if [ "$changed" -gt 0 ]; then
    echo "DRIFT: $changed system file(s) differ (instance V$TO_V, system V$FROM_V)." >&2
    exit 1
  fi
  [ "$missing_src" -gt 0 ] && { echo "DRIFT: $missing_src system file(s) missing from the system repo." >&2; exit 1; }
  echo "IN SYNC: instance V$TO_V matches system V$FROM_V."
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN: $changed file(s) would change (instance V$TO_V, system V$FROM_V)."
else
  echo "SYNCED: $copied file(s) updated (instance now V$FROM_V, was V$TO_V)."
fi

if [ "$missing_src" -gt 0 ]; then
  echo "WARNING: $missing_src listed path(s) absent from the system repo." >&2
fi

if [ "$copied" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  echo ""
  echo "Next: review the diff in $TO, then commit the data repo."
  echo "  cd $TO && git diff --stat && git add -A && git commit -m 'sync: system files to V$FROM_V'"
fi
