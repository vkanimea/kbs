#!/bin/bash
# KBS Topic Index — Lightweight Local Search (V0.115)
# Builds a simple grep-friendly index for rapid topic selection before LLM synthesis.
# Not a replacement for LLM reasoning — an accelerator for large KBs.
#
# Usage:
#   ~/kbs/scripts/topic-index.sh           # rebuild index
#   ~/kbs/scripts/topic-index.sh "search terms"  # search index

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
TOPICS_DIR="$KBS_PATH/kb/$KB_NAME/wiki/topics"
INDEX_FILE="$KBS_PATH/kb/$KB_NAME/.topic-index"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
NC='\033[0m'

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ─── Build Index ──────────────────────────────────────────────────────────────
build_index() {
    echo "Building topic index..."
    > "$INDEX_FILE"
    
    if [ ! -d "$TOPICS_DIR" ]; then
        echo "No topics directory found at $TOPICS_DIR"
        exit 1
    fi
    
    find "$TOPICS_DIR" -name "*.md" -not -name "INDEX.md" | while read -r f; do
        topic=$(basename "$f" .md)
        # Extract TLDR (first line after the TLDR: label, up to 120 chars)
        tldr=$(grep -m1 "^TLDR:" "$f" 2>/dev/null | sed 's/^TLDR:[[:space:]]*//' | cut -c1-120)
        # Extract all linked topics [[name]]
        links=$(grep -oE '\[\[[^\]]+\]\]' "$f" 2>/dev/null | tr '\n' ' ' | sed 's/\[\[//g; s/\]\]//g')
        # Extract confidence HIGH claims count
        high_claims=$(grep -c "HIGH" "$f" 2>/dev/null)
        high_claims=${high_claims:-0}
        # Last modified
        mtime=$(date -r "$f" "+%Y-%m-%d" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null)
        
        echo "TOPIC|$topic|$mtime|$high_claims|$tldr|$links" >> "$INDEX_FILE"
    done
    
    COUNT=$(wc -l < "$INDEX_FILE" | tr -d ' ')
    echo "[$TIMESTAMP] INDEX_BUILD | $KB_NAME | TOPICS: $COUNT" >> "$KBS_PATH/log.md"
    echo -e "${GREEN}✅ Index built: $COUNT topics${NC}"
}

# ─── Search Index ─────────────────────────────────────────────────────────────
search_index() {
    query="$1"
    
    if [ ! -f "$INDEX_FILE" ]; then
        echo "Index not found. Building first..."
        build_index
    fi
    
    echo -e "${CYAN}Searching for: $query${NC}"
    echo ""
    
    # Search across topic name, TLDR, and links
    RESULTS=$(grep -i "$query" "$INDEX_FILE" 2>/dev/null | head -20)
    
    if [ -z "$RESULTS" ]; then
        echo "No matches. Try a broader term, or rebuild the index:"
        echo "  ~/kbs/scripts/topic-index.sh"
        exit 0
    fi
    
    echo "$RESULTS" | while IFS='|' read -r _ topic mtime high_claims tldr links; do
        echo -e "${GREEN}[[${topic}]]${NC} (mod: $mtime, HIGH claims: $high_claims)"
        echo "  $tldr"
        if [ -n "$links" ]; then
            echo -e "  ${YELLOW}Links:${NC} $links"
        fi
        echo ""
    done
    
    MATCH_COUNT=$(echo "$RESULTS" | wc -l | tr -d ' ')
    echo -e "${CYAN}$MATCH_COUNT topic(s) matched.${NC}"
    echo "Run a query on these: Follow agents.md. Query $KB_NAME: [your question]"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
if [ $# -eq 0 ]; then
    build_index
else
    search_index "$*"
fi
