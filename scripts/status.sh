#!/bin/bash
# KBS Status Check — Linux/macOS (V11.3)
# Usage: ~/kbs/scripts/status.sh

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║         Knowledge Base System — Status              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}KBS Path : $KBS_PATH${NC}"
echo -e "${YELLOW}KB Name  : $KB_NAME${NC}"
echo ""

# Topics
TOPICS=$(find "$KBS_PATH/kb/$KB_NAME/wiki/topics" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "📚 Topics          : ${TOPICS}"

# Raw files
RAW=$(find "$KBS_PATH/kb/$KB_NAME/raw" \( -name "*.md" -o -name "*.txt" \) 2>/dev/null | wc -l | tr -d ' ')
echo -e "📄 Raw files       : ${RAW}"

# Outputs
OUTPUTS=$(find "$KBS_PATH/kb/$KB_NAME/outputs" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "📤 Outputs         : ${OUTPUTS}"

# Pending
PENDING=$(find "$KBS_PATH/kb/$KB_NAME/outputs" -name "pending-*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PENDING" -gt 0 ]; then
    echo -e "⏳ Pending approvals: ${RED}${PENDING} — review needed${NC}"
else
    echo -e "⏳ Pending approvals: ${GREEN}${PENDING}${NC}"
fi

# Failures
if [ -f "$KBS_PATH/FAILURES.md" ]; then
    FAILURES=$(grep -c "^## 20" "$KBS_PATH/FAILURES.md" 2>/dev/null)
    FAILURES=${FAILURES:-0}
    UNRESOLVED=$(grep -c "Resolved: No" "$KBS_PATH/FAILURES.md" 2>/dev/null)
    UNRESOLVED=${UNRESOLVED:-0}
    echo -e "⚠️  Total failures  : ${FAILURES}"
    if [ "$UNRESOLVED" -gt 0 ]; then
        echo -e "   Unresolved     : ${RED}${UNRESOLVED} — action needed${NC}"
    else
        echo -e "   Unresolved     : ${GREEN}0${NC}"
    fi
fi

# Achievements
if [ -f "$KBS_PATH/CAREER.md" ]; then
    ACHIEVEMENTS=$(grep -c "^## 20" "$KBS_PATH/CAREER.md" 2>/dev/null)
    ACHIEVEMENTS=${ACHIEVEMENTS:-0}
    echo -e "🏆 Achievements    : ${ACHIEVEMENTS}"
fi

# Last session close
LAST_CLOSE=$(grep "SESSION_CLOSE" "$KBS_PATH/log.md" 2>/dev/null | grep -v '\[ts\]' | tail -1 | awk -F'|' '{print $1}' | xargs)
if [ -n "$LAST_CLOSE" ]; then
    echo -e "🕐 Last close      : ${LAST_CLOSE}"
else
    echo -e "🕐 Last close      : ${RED}Never — run session close today${NC}"
fi

# Last health check
LAST_HC=$(find "$KBS_PATH/kb/$KB_NAME/outputs" -name "health-check-*.md" 2>/dev/null | sort | tail -1 | xargs basename 2>/dev/null | sed 's/health-check-//' | sed 's/.md//')
if [ -n "$LAST_HC" ]; then
    echo -e "🔍 Last health check: ${LAST_HC}"
else
    echo -e "🔍 Last health check: ${YELLOW}None — run monthly health check${NC}"
fi

# Close streak
STREAK_FILE="$KBS_PATH/.close-streak"
STREAK=0
if [ -f "$STREAK_FILE" ]; then
    STREAK=$(cat "$STREAK_FILE" 2>/dev/null || echo "0")
fi
if [ "$STREAK" -gt 2 ]; then
    echo -e "🔥 Close streak    : ${GREEN}$STREAK days${NC}"
elif [ "$STREAK" -gt 0 ]; then
    echo -e "✅ Close streak    : ${GREEN}$STREAK days${NC}"
else
    echo -e "⚠️  Close streak    : ${RED}Broken or not started${NC}"
fi

echo ""
echo -e "${CYAN}Quick prompts:${NC}"
echo "  Session close : Follow agents.md. Close session for $KB_NAME"
echo "  Ingest        : Follow agents.md. Ingest $KB_NAME"
echo "  Health check  : Follow agents.md and SYSTEM.md. Run health check on $KB_NAME"
echo "  Show pending  : Follow agents.md. Show me all pending approvals"
echo ""
echo -e "${CYAN}Helper scripts:${NC}"
echo "  Auto-close    : $KBS_PATH/scripts/auto-close.sh"
echo "  Due actions   : $KBS_PATH/scripts/due-actions.sh"
echo "  Topic search  : $KBS_PATH/scripts/topic-index.sh 'search term'"
echo ""
