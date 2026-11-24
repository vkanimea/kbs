#!/bin/bash
# KBS Hourly Ingest — staging-only lifecycle (staging-only design, SWOT I2 option A)
#
# This script does NOT ingest anything and does NOT move files.
# Ingestion is an LLM procedure (templates/reference/ingestion.md) run by the owner
# via "Follow agents.md. Ingest [KB]". A file being discovered or referenced is not
# ingestion success; therefore nothing here marks a file processed.
#
# What it does (idempotent, safe to re-run):
#   1. Scans top-level raw/ for candidate files (md/txt/csv/json).
#   2. Classifies each by whether an entry file (INBOX.md, CHAT_INBOX.md) references it:
#        referenced   → ingested-or-in-pipeline (state: referenced)
#        unreferenced → ORPHAN — reported for the owner, never marked complete
#   3. Logs counts to log.md (HOURLY_INGEST). Files stay in raw/ as immutable originals.
#   4. Rebuilds the RAG index only if kb/<KB>/wiki content changed since the last
#      successful index (stamp file), and reports indexing failure separately.
#
# Schedule: 0 * * * * ~/kbs/scripts/hourly-ingest.sh
# Usage:    ~/kbs/scripts/hourly-ingest.sh

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"

# Portable timeout: GNU `timeout` (Linux), `gtimeout` (Homebrew/coreutils on macOS),
# or no limit if neither is installed (stock macOS).
if command -v timeout >/dev/null 2>&1; then run_timeout() { timeout "$@"; }
elif command -v gtimeout >/dev/null 2>&1; then run_timeout() { gtimeout "$@"; }
else run_timeout() { local _d="$1"; shift; "$@"; }
fi

# Rebuild RAG index only when wiki content changed since last success (defined
# here so the no-files early-exit path can call it).
rag_maybe_rebuild() {
    [ -x "$KBS_PATH/scripts/rag-index.sh" ] || return 0
    local latest
    latest=$(find "$KB_DIR/wiki" -name '*.md' -newer "$STAMP" -print -quit 2>/dev/null || true)
    if [ ! -f "$STAMP" ] || [ -n "$latest" ]; then
        if run_timeout 600 "$KBS_PATH/scripts/rag-index.sh" 2>&1; then
            mkdir -p "$(dirname "$STAMP")"
            touch "$STAMP"
            echo "[$TIMESTAMP] RAG_INDEX | $KB_NAME | re-indexed (wiki changed since last index)" >> "$LOG"
        else
            # Indexing failure is separate from ingestion state — WARN only.
            echo "[$TIMESTAMP] RAG_INDEX | $KB_NAME | FAILED (Ollama unreachable?)" >> "$LOG"
        fi
    else
        echo "[$TIMESTAMP] RAG_INDEX | $KB_NAME | skipped (wiki unchanged since last index)" >> "$LOG"
    fi
}

RAW_DIR="$KBS_PATH/kb/$KB_NAME/raw"
KB_DIR="$KBS_PATH/kb/$KB_NAME"
LOG="$KBS_PATH/log.md"
STAMP="$KB_DIR/.rag-index-stamp"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$RAW_DIR"

# ─── 1. Find candidate files (null-safe: handles spaces in filenames) ─────────
mapfile -d '' FILES < <(find "$RAW_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.txt' -o -name '*.csv' -o -name '*.json' \) -print0 2>/dev/null)

if [ "${#FILES[@]}" -eq 0 ]; then
    echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | No raw files staged" >> "$LOG"
    # No candidates, but the RAG index may still need a rebuild after wiki edits.
    rag_maybe_rebuild
    exit 0
fi

# ─── 2. Classify by INBOX reference — never move, never mark processed ────────
REFERENCED=0
ORPHANS=()
for f in "${FILES[@]}"; do
    BASENAME=$(basename "$f")
    # A file counts as referenced when any entry file names it (Source line or body).
    if grep -rql -- "$BASENAME" "$KB_DIR/INBOX.md" "$KB_DIR/CHAT_INBOX.md" 2>/dev/null; then
        REFERENCED=$((REFERENCED + 1))
    else
        ORPHANS+=("$BASENAME")
    fi
done

LOG_LINE="[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | files=${#FILES[@]} referenced=$REFERENCED orphans=${#ORPHANS[@]} (staging-only: no files moved)"
echo "$LOG_LINE" >> "$LOG"

if [ "${#ORPHANS[@]}" -gt 0 ]; then
    echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | ORPHANS (unreferenced in INBOX.md/CHAT_INBOX.md): ${ORPHANS[*]}" >> "$LOG"
    echo "Orphaned files (no INBOX reference — they are invisible to ingestion):" >&2
    printf '  %s\n' "${ORPHANS[@]}" >&2
fi

# ─── 3. RAG index rebuild (see rag_maybe_rebuild above) ───────────────────────
rag_maybe_rebuild
