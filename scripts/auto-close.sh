#!/bin/bash
# KBS Auto-Close Helper — V0.114
# Generates a minimal close report and tracks streaks.
# Run manually when you missed a close, or schedule via cron for a nudge.
#
# Usage: ~/kbs/scripts/auto-close.sh

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
LOG="$KBS_PATH/log.md"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d')

# ─── Streak Calculation ───────────────────────────────────────────────────────
STREAK=0

if [ -f "$LOG" ]; then
    # Collect all unique SESSION_CLOSE dates (real entries only, not [ts] doc examples)
    CLOSE_DATES=$(grep "SESSION_CLOSE" "$LOG" 2>/dev/null | grep -v '\[ts\]' | awk '{print $1}' | tr -d '[]' | sort -u -r)
    if [ -n "$CLOSE_DATES" ]; then
        # Walk backwards from the most recent close, counting consecutive days
        MOST_RECENT="$(echo "$CLOSE_DATES" | head -1)"
        # Broken if the most recent close is older than yesterday (gap > 1 day)
        MOST_RECENT_EPOCH=$(date -d "$MOST_RECENT" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$MOST_RECENT" +%s 2>/dev/null)
        TODAY_EPOCH=$(date -d "$TODAY" +%s 2>/dev/null || date +%s)
        if [ -n "$MOST_RECENT_EPOCH" ] && [ -n "$TODAY_EPOCH" ] && [ $(( (TODAY_EPOCH - MOST_RECENT_EPOCH) / 86400 )) -le 1 ]; then
            EXPECTED="$MOST_RECENT"
            for d in $CLOSE_DATES; do
                if [ "$d" = "$EXPECTED" ]; then
                    STREAK=$((STREAK + 1))
                    EXPECTED=$(date -d "$EXPECTED -1 day" +%Y-%m-%d 2>/dev/null || date -j -v-1d -f "%Y-%m-%d" "$EXPECTED" +%Y-%m-%d)
                else
                    break
                fi
            done
        fi
        # Persist for the dashboard
        echo "$STREAK" > "$KBS_PATH/.close-streak"
    fi
fi

# ─── Pending Items Summary ────────────────────────────────────────────────────
PENDING=0
if [ -d "$KBS_PATH/kb/$KB_NAME/outputs" ]; then
    PENDING=$(find "$KBS_PATH/kb/$KB_NAME/outputs" -name "pending-*.md" 2>/dev/null | wc -l | tr -d ' ')
fi

HELD=0
if [ -f "$KBS_PATH/INBOX.md" ]; then
    # Count entries in Held section (rough heuristic: lines under ## Held)
    HELD=$(grep -c "^## .*Held" "$KBS_PATH/INBOX.md" 2>/dev/null || echo "0")
fi

OPEN_Q=0
if [ -f "$KBS_PATH/INBOX.md" ]; then
    OPEN_Q=$(grep -c "^## .*Open Question" "$KBS_PATH/INBOX.md" 2>/dev/null || echo "0")
fi

OVERDUE_ACTIONS=0
if [ -f "$KBS_PATH/ACTIONS.md" ]; then
    # Find actions with Done: No and past due date (best-effort)
    OVERDUE_ACTIONS=$(grep -c "Done: No" "$KBS_PATH/ACTIONS.md" 2>/dev/null || echo "0")
fi

# ─── Output Report ────────────────────────────────────────────────────────────
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║         KBS Auto-Close Helper Report                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "Date: $TIMESTAMP"
echo -e "KB: $KB_NAME"
echo ""

if [ "$STREAK" -gt 2 ]; then
    echo -e "🔥 Close streak: ${GREEN}$STREAK days${NC}"
elif [ "$STREAK" -gt 0 ]; then
    echo -e "✅ Close streak: ${GREEN}$STREAK days${NC}"
else
    echo -e "⚠️  Close streak: ${RED}Broken — last close >1 day ago${NC}"
fi

echo ""
echo -e "${YELLOW}Pending Items:${NC}"
echo -e "  Pending approvals : $PENDING"
echo -e "  Held entries      : $HELD"
echo -e "  Open questions    : $OPEN_Q"
echo -e "  Open actions      : $OVERDUE_ACTIONS"

echo ""
echo -e "${CYAN}Next Steps:${NC}"

if [ "$HELD" -gt 0 ] || [ "$PENDING" -gt 0 ] || [ "$OVERDUE_ACTIONS" -gt 0 ]; then
    echo "  Run: Follow agents.md. Close session for $KB_NAME"
else
    echo "  Nothing pending — run close to log today's session."
fi

if [ "$PENDING" -gt 0 ]; then
    echo "  Review: Follow agents.md. Show me all pending approvals"
fi
if [ "$OVERDUE_ACTIONS" -gt 0 ]; then
    echo "  Check: Follow agents.md. Process ACTIONS.md"
fi

echo ""

# ─── Log the auto-close check ─────────────────────────────────────────────────
echo "[$TIMESTAMP] AUTO_CLOSE | $KB_NAME | STREAK: $STREAK | PENDING: $PENDING | HELD: $HELD | ACTIONS: $OVERDUE_ACTIONS" >> "$LOG"

# ─── Desktop notification ─────────────────────────────────────────────────────
MSG="KBS: $PENDING pending, $HELD held, $OVERDUE_ACTIONS open actions. Streak: $STREAK days."
if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$MSG\" with title \"KBS Auto-Close\""
fi
if command -v notify-send &>/dev/null; then
    notify-send "KBS Auto-Close" "$MSG"
fi
