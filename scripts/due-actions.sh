#!/bin/bash
# KBS Due Actions Reminder — V0.113
# Checks ACTIONS.md for overdue items and emits desktop notifications.
# Schedule: 0 9 * * 1-5 ~/kbs/scripts/due-actions.sh
#
# Usage: ~/kbs/scripts/due-actions.sh

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
ACTIONS_FILE="$KBS_PATH/ACTIONS.md"
LOG="$KBS_PATH/log.md"

YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TODAY_EPOCH=$(date +%s)

OVERDUE_COUNT=0
DUE_THIS_WEEK=0
OVERDUE_LIST=""

if [ -f "$ACTIONS_FILE" ]; then
    # Best-effort parsing of action entries
    # Look for **Due:** YYYY-MM-DD or **Done:** No patterns
    IN_OPEN=0
    CURRENT_DUE=""
    CURRENT_TITLE=""
    
    while IFS= read -r line; do
        # Detect new action entry
        if echo "$line" | grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}"; then
            # Check previous action if it was open
            if [ "$IN_OPEN" -eq 1 ] && [ -n "$CURRENT_DUE" ]; then
                DUE_EPOCH=$(date -d "$CURRENT_DUE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$CURRENT_DUE" +%s 2>/dev/null)
                if [ -n "$DUE_EPOCH" ]; then
                    DAYS_UNTIL=$(( (DUE_EPOCH - TODAY_EPOCH) / 86400 ))
                    if [ "$DAYS_UNTIL" -lt 0 ]; then
                        OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
                        OVERDUE_LIST="$OVERDUE_LIST\n  • $CURRENT_TITLE (due $CURRENT_DUE)"
                    elif [ "$DAYS_UNTIL" -le 7 ]; then
                        DUE_THIS_WEEK=$((DUE_THIS_WEEK + 1))
                    fi
                fi
            fi
            IN_OPEN=0
            CURRENT_DUE=""
            CURRENT_TITLE=$(echo "$line" | sed 's/^## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} | //')
        fi
        
        if echo "$line" | grep -q "Done: No"; then
            IN_OPEN=1
        fi
        
        if echo "$line" | grep -qE "Due: [0-9]{4}-[0-9]{2}-[0-9]{2}"; then
            CURRENT_DUE=$(echo "$line" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
        fi
        
        if echo "$line" | grep -q "Due: next session"; then
            CURRENT_DUE=$(date +%Y-%m-%d)
        fi
    done < "$ACTIONS_FILE"
    
    # Check last entry
    if [ "$IN_OPEN" -eq 1 ] && [ -n "$CURRENT_DUE" ]; then
        DUE_EPOCH=$(date -d "$CURRENT_DUE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$CURRENT_DUE" +%s 2>/dev/null)
        if [ -n "$DUE_EPOCH" ]; then
            DAYS_UNTIL=$(( (DUE_EPOCH - TODAY_EPOCH) / 86400 ))
            if [ "$DAYS_UNTIL" -lt 0 ]; then
                OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
                OVERDUE_LIST="$OVERDUE_LIST\n  • $CURRENT_TITLE (due $CURRENT_DUE)"
            elif [ "$DAYS_UNTIL" -le 7 ]; then
                DUE_THIS_WEEK=$((DUE_THIS_WEEK + 1))
            fi
        fi
    fi
fi

# ─── Output ───────────────────────────────────────────────────────────────────
if [ "$OVERDUE_COUNT" -gt 0 ] || [ "$DUE_THIS_WEEK" -gt 0 ]; then
    echo -e "${YELLOW}KBS Actions Reminder${NC}"
    echo "===================="
    if [ "$OVERDUE_COUNT" -gt 0 ]; then
        echo -e "${RED}Overdue: $OVERDUE_COUNT${NC}"
        echo -e "$OVERDUE_LIST"
    fi
    if [ "$DUE_THIS_WEEK" -gt 0 ]; then
        echo -e "${GREEN}Due this week: $DUE_THIS_WEEK${NC}"
    fi
    echo ""
    echo "Run: Follow agents.md. Process ACTIONS.md"
    
    # Desktop notification
    MSG="KBS: $OVERDUE_COUNT overdue, $DUE_THIS_WEEK due this week."
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"$MSG\" with title \"KBS Due Actions\""
    fi
    if command -v notify-send &>/dev/null; then
        notify-send "KBS Due Actions" "$MSG"
    fi
    
    echo "[$TIMESTAMP] DUE_ACTIONS | $KB_NAME | OVERDUE: $OVERDUE_COUNT | DUE_THIS_WEEK: $DUE_THIS_WEEK" >> "$LOG"
else
    echo -e "${GREEN}No overdue or upcoming actions.${NC}"
fi
