#!/bin/bash
# KBS Due Actions Reminder — V0.116
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
    # Best-effort parsing of action entries.
    #
    # The DOCUMENTED contract is that `**Done:** No` marks an open action, so
    # that marker is the sole source of truth — NOT section headings. This
    # matters: the file carries a stale `## Completed Actions` heading with
    # still-open (`**Done:** No`) entries beneath it, and a later
    # `## Open Actions`-style heading is not guaranteed. Gating on headings
    # produced false negatives both ways.
    #
    # The one region to exclude is the template/example at the top of the file:
    # it sits BEFORE the `## Open Actions` heading and uses placeholder dates
    # (YYYY-MM-DD / 20XX-01-01), which are filtered out by the date check below.
    IN_ENTRY=0
    ENTRY_DONE=0
    SEEN_OPEN_HEADING=0
    CURRENT_DUE=""
    CURRENT_TITLE=""

    flush_entry() {
        # Count the entry just ended, if it was open and had a resolvable due date.
        [ "$IN_ENTRY" -eq 1 ] || return 0
        [ "$ENTRY_DONE" -eq 0 ] || return 0
        [ -n "$CURRENT_DUE" ] || return 0
        local due_epoch
        due_epoch=$(date -d "$CURRENT_DUE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$CURRENT_DUE" +%s 2>/dev/null || true)
        [ -n "$due_epoch" ] || return 0
        local days_until
        days_until=$(( (due_epoch - TODAY_EPOCH) / 86400 ))
        if [ "$days_until" -lt 0 ]; then
            OVERDUE_COUNT=$((OVERDUE_COUNT + 1))
            OVERDUE_LIST="$OVERDUE_LIST\n  • $CURRENT_TITLE (due $CURRENT_DUE)"
        elif [ "$days_until" -le 7 ]; then
            DUE_THIS_WEEK=$((DUE_THIS_WEEK + 1))
        fi
        return 0
    }

    while IFS= read -r line; do
        # Note the live section once seen, but never gate on it.
        case "$line" in
            "## Open Actions"*) SEEN_OPEN_HEADING=1; continue ;;
        esac

        # New dated entry: flush the previous one and reset per-entry state.
        if printf '%s' "$line" | grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}'; then
            flush_entry
            IN_ENTRY=1
            ENTRY_DONE=0
            CURRENT_DUE=""
            CURRENT_TITLE=$(printf '%s' "$line" | sed 's/^## [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} | //')
            continue
        fi

        # Entries are written with bold markers: "**Done:** No" / "**Due:**".
        # Match the MARKER LINE, not the marker text anywhere in the file — the
        # template prose also contains the bare strings, which previously made
        # every entry look closed except that one prose line.
        if printf '%s' "$line" | grep -qE '^\*\*Done:\*\*[[:space:]]+No[[:space:]]*$'; then
            ENTRY_DONE=0
        elif printf '%s' "$line" | grep -qE '^\*\*Done:\*\*'; then
            ENTRY_DONE=1
        fi

        # Prefer the LAST YYYY-MM-DD on the **Due:** line. Annotated entries can
        # read "awaiting X (re-dated from YYYY-MM-DD)" where the earlier date is
        # history, not the live deadline.
        if printf '%s' "$line" | grep -qE '^\*\*Due:\*\*'; then
            CURRENT_DUE=$(printf '%s' "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -n1)
            if printf '%s' "$line" | grep -q 'next session'; then
                CURRENT_DUE=$(date +%Y-%m-%d)
            fi
        fi
    done < "$ACTIONS_FILE"

    # Flush the final entry (no trailing header to trigger it).
    flush_entry
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
