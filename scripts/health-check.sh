#!/bin/bash
# KBS Health Check Runner — V11.3
# Schedule monthly: 0 10 1 * * ~/kbs/scripts/health-check.sh
#
# This script sends a desktop notification reminding you to run the health check.
# To automate the actual LLM call, install llm-cli and uncomment the curl section.

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
LOG="$KBS_PATH/health-log.txt"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Health check reminder triggered" >> "$LOG"

# Check pending approvals
PENDING=$(find "$KBS_PATH/kb/$KB_NAME/outputs" -name "pending-*.md" -mtime -35 2>/dev/null | wc -l | tr -d ' ')
UNRESOLVED=$(grep -c "Resolved: No" "$KBS_PATH/FAILURES.md" 2>/dev/null || echo "0")

MSG="KBS Monthly Health Check due."
[ "$PENDING" -gt 0 ] && MSG="$MSG $PENDING pending approvals."
[ "$UNRESOLVED" -gt 0 ] && MSG="$MSG $UNRESOLVED unresolved failures."

# macOS notification
if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$MSG\" with title \"Knowledge Base System\""
fi

# Linux notification
if command -v notify-send &>/dev/null; then
    notify-send "Knowledge Base System" "$MSG"
fi

echo "[$TIMESTAMP] Reminder sent: $MSG" >> "$LOG"
echo ""
echo "KBS Health Check Reminder"
echo "========================="
echo "$MSG"
echo ""
echo "Run in your LLM client:"
echo "  Follow agents.md and SYSTEM.md. Run health check on $KB_NAME."
echo "  Report findings. Write proposals. Do not change anything automatically."
echo ""

# ─── Optional: Automated LLM call (requires llm-cli or equivalent) ─────────────
# Uncomment and configure for your LLM CLI tool:
#
# HEALTH_PROMPT="Follow agents.md and SYSTEM.md. Run health check on $KB_NAME. Report findings. Write proposals. Do not change anything."
# echo "$HEALTH_PROMPT" | llm --system "$KBS_PATH/agents.md" >> "$KBS_PATH/kb/$KB_NAME/outputs/health-check-$(date +%Y-%m-%d).md"
