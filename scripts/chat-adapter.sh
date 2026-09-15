#!/bin/bash
# KBS Universal Chat Adapter — V0.113
# Captures chat output from any LLM into CHAT_INBOX.md + raw transcript.
# The adapter captures; the LLM extracts insights later during processing —
# this script does NOT pretend to identify "key insights" itself.
#
# Usage:
#   echo "chat text" | ./chat-adapter.sh
#   ./chat-adapter.sh transcript.txt
#   ./chat-adapter.sh "Direct text"

set -e

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
CHAT_INBOX="${CHAT_INBOX:-$KBS_PATH/CHAT_INBOX.md}"
CHAT_RAW_DIR="${CHAT_RAW_DIR:-$KBS_PATH/kb/$KB_NAME/raw/chat-transcripts}"

GREEN='\033[0;32m'; NC='\033[0m'

mkdir -p "$(dirname "$CHAT_INBOX")" "$CHAT_RAW_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
DATE_STAMP=$(date '+%Y-%m-%d')
TIME_STAMP=$(date '+%H%M%S')

# ─── Input ─────────────────────────────────────────────────────────────────────
if [ ! -t 0 ]; then
    INPUT=$(cat); SOURCE="stdin"
elif [ -f "${1:-}" ]; then
    INPUT=$(cat "$1"); SOURCE="file:$(basename "$1")"
elif [ -n "${1:-}" ]; then
    INPUT="$1"; SOURCE="argument"
else
    echo "Usage: echo 'text' | $0   |   $0 file.txt   |   $0 'text'"
    exit 0
fi

# ─── LLM detection (best-effort label only) ────────────────────────────────────
LOWER=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]')
case "$LOWER" in
    *claude*|*anthropic*) LLM_NAME="Claude" ;;
    *chatgpt*|*gpt-4*|*openai*) LLM_NAME="ChatGPT" ;;
    *gemini*|*bard*) LLM_NAME="Gemini" ;;
    *llama*|*ollama*) LLM_NAME="Llama-local" ;;
    *mistral*) LLM_NAME="Mistral-local" ;;
    *) LLM_NAME="Unknown-LLM" ;;
esac

TITLE=$(echo "$INPUT" | head -1 | sed 's/^#*//' | cut -c1-60 | xargs)
RAW_FILENAME="chat-${DATE_STAMP}-${TIME_STAMP}-${LLM_NAME}.md"

# ─── Raw transcript (full fidelity) ────────────────────────────────────────────
{
    echo "# Chat with $LLM_NAME"
    echo "**Date:** $TIMESTAMP | **Source:** $SOURCE"
    echo ""
    echo "---"
    echo ""
    echo "$INPUT"
} > "$CHAT_RAW_DIR/$RAW_FILENAME"

# ─── CHAT_INBOX stub (insights extracted by LLM during processing) ─────────────
{
    echo ""
    echo "## $TIMESTAMP | Conversation with $LLM_NAME"
    echo "**Source:** $SOURCE"
    echo "**Topic:** $TITLE"
    echo "**Confidence:** LOW"
    echo ""
    echo "### Key Insights"
    echo "- _To be extracted during processing — see raw transcript_"
    echo ""
    echo "### Action Items"
    echo "- [ ] Run: Follow agents.md. Process CHAT_INBOX.md"
    echo ""
    echo "### Raw Transcript"
    echo "raw/chat-transcripts/$RAW_FILENAME"
} >> "$CHAT_INBOX"

echo -e "${GREEN}✅ Captured ($LLM_NAME) → CHAT_INBOX.md${NC}"
echo -e "${GREEN}   Transcript: $CHAT_RAW_DIR/$RAW_FILENAME${NC}"
echo "Next: Follow agents.md. Process CHAT_INBOX.md"
