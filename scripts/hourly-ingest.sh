#!/bin/bash
# KBS Hourly Ingest — V0.113
# Checks raw/ for unprocessed files, ingests them, moves to raw/processed/.
# Post-step: rebuilds the RAG semantic index (scripts/rag-index.sh) if available.
# Schedule: 0 * * * * ~/kbs/scripts/hourly-ingest.sh
#
# Usage: ~/kbs/scripts/hourly-ingest.sh

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
RAW_DIR="$KBS_PATH/kb/$KB_NAME/raw"
PROCESSED_DIR="$RAW_DIR/processed"
LOG="$KBS_PATH/log.md"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$PROCESSED_DIR"

# Find unprocessed files (not already in processed/)
UNPROCESSED=$(find "$RAW_DIR" -maxdepth 1 -type f \( -name "*.md" -o -name "*.txt" -o -name "*.csv" -o -name "*.json" \) 2>/dev/null)

COUNT=$(echo "$UNPROCESSED" | grep -c "\." 2>/dev/null || echo "0")

if [ "$COUNT" -eq 0 ] || [ -z "$UNPROCESSED" ]; then
    echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | No unprocessed files" >> "$LOG"
    exit 0
fi

echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | Files: $COUNT" >> "$LOG"

# Move each file to processed after ingestion is triggered
# NOTE: Actual ingestion requires LLM call. This script prepares and logs.
# The owner runs: Follow agents.md. Ingest [KB] in their LLM client.
# Level 2+ can wire LLM CLI into the stub below.

echo "$UNPROCESSED" | while read -r f; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    echo "  → $BASENAME"
    # Move to processed (LLM ingestion happens separately or via auto below)
    mv "$f" "$PROCESSED_DIR/$BASENAME"
    echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | Processed: $BASENAME" >> "$LOG"
done

echo "[$TIMESTAMP] HOURLY_INGEST | $KB_NAME | Complete — $COUNT files moved to processed/" >> "$LOG"

# ─── Post-ingest: rebuild RAG semantic index (best effort) ────────────────────
RAG_INDEX="$KBS_PATH/scripts/rag-index.sh"
if [ -x "$RAG_INDEX" ]; then
  if timeout 600 "$RAG_INDEX" 2>&1; then
    echo "[$TIMESTAMP] RAG_INDEX | $KB_NAME | re-indexed topics" >> "$LOG"
  else
    echo "[$TIMESTAMP] RAG_INDEX | $KB_NAME | FAILED (Ollama unreachable?)" >> "$LOG"
  fi
fi

# ─── Optional: Automated LLM call (requires LLM CLI) ──────────────────────────
# Uncomment and configure for your LLM CLI tool (e.g., Anthropic CLI, llm by Simon Willison):
#
# INGEST_PROMPT="Follow agents.md. Ingest $KB_NAME"
# echo "$INGEST_PROMPT" | llm --system "$KBS_PATH/agents.md" >> "$KBS_PATH/kb/$KB_NAME/outputs/hourly-ingest-$(date +%Y-%m-%d-%H).md"
