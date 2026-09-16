#!/bin/bash
# Knowledge Base System (KBS) V0.115 — Linux/macOS Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash
#   KBS_PATH=/custom/path KB_NAME=myproject ./install.sh
#
# If run from a cloned repo, templates are copied locally (no network needed).
# If run standalone (curl pipe), templates are downloaded; any failure aborts loudly.

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
REPO_URL="https://raw.githubusercontent.com/vkanimea/kbs/main"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-/dev/null}")" 2>/dev/null && pwd || echo "")"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Knowledge Base System (KBS) V0.115 Installer            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}📍 Path : $KBS_PATH${NC}"
echo -e "${YELLOW}📚 KB   : $KB_NAME${NC}"
echo ""

# ─── Directories ───────────────────────────────────────────────────────────────
mkdir -p "$KBS_PATH"/{reference,scripts/windows,docs}
mkdir -p "$KBS_PATH/kb/$KB_NAME"/{raw/chat-transcripts,raw-assets/{pdfs,images},wiki/{topics,snapshots},outputs}
echo -e "${GREEN}✅ Directories created${NC}"

# ─── File installer: local copy if available, else download; abort on failure ──
TEMPLATES=(agents.md SYSTEM.md DECISIONS.md INBOX.md CHAT_INBOX.md FAILURES.md SUCCESSES.md CAREER.md ACTIONS.md JOURNAL.md PROMPTS.md log.md)
REFERENCES=(session-close.md ingestion.md chat-input.md failures.md successes.md actions.md journal.md health-check.md)
SCRIPTS=(chat-adapter.sh chat-api-adapter.py health-check.sh status.sh auto-close.sh due-actions.sh topic-index.sh youtube-ingest.sh hourly-ingest.sh rag.py rag-index.sh rag-query.sh)

FAILED=0
install_file() {
  local src="$1" dst="$2"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$src" ]; then
    cp "$SCRIPT_DIR/$src" "$dst" && echo -e "${GREEN}  ✓ $src (local)${NC}" && return 0
  fi
  if command -v curl &>/dev/null; then
    curl -fsSL "$REPO_URL/$src" -o "$dst" && echo -e "${GREEN}  ✓ $src${NC}" && return 0
  elif command -v wget &>/dev/null; then
    wget -q "$REPO_URL/$src" -O "$dst" && echo -e "${GREEN}  ✓ $src${NC}" && return 0
  fi
  echo -e "${RED}  ✗ $src — FAILED${NC}"
  FAILED=1
  return 0
}

echo -e "${CYAN}📝 Installing templates...${NC}"
for f in "${TEMPLATES[@]}"; do install_file "templates/$f" "$KBS_PATH/$f"; done
for f in "${REFERENCES[@]}"; do install_file "templates/reference/$f" "$KBS_PATH/reference/$f"; done
install_file "CHANGELOG.md" "$KBS_PATH/CHANGELOG.md"
install_file "VERSION" "$KBS_PATH/VERSION"

echo -e "${CYAN}🔧 Installing scripts...${NC}"
for f in "${SCRIPTS[@]}"; do install_file "scripts/$f" "$KBS_PATH/scripts/$f"; done
install_file "scripts/windows/status.ps1" "$KBS_PATH/scripts/windows/status.ps1"

# Install examples (optional — copy locally if available, never fail on download)
echo -e "${CYAN}📦 Installing starter KB...${NC}"
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/examples/starter-kb" ]; then
    mkdir -p "$KBS_PATH/examples"
    cp -r "$SCRIPT_DIR/examples/starter-kb" "$KBS_PATH/examples/starter-kb" && echo -e "${GREEN}  ✓ examples/starter-kb (local)${NC}"
fi
chmod +x "$KBS_PATH/scripts/"*.sh "$KBS_PATH/scripts/"*.py 2>/dev/null || true

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo -e "${RED}❌ INSTALLATION INCOMPLETE — one or more files failed to install.${NC}"
  echo -e "${RED}   Check your network, or clone the repo and run ./install.sh locally:${NC}"
  echo "   git clone https://github.com/vkanimea/kbs.git && cd kbs && ./install.sh"
  exit 1
fi

# ─── Generated files ───────────────────────────────────────────────────────────
cat > "$KBS_PATH/.env.template" <<EOF
# KBS V0.115 — copy to .env and edit
KBS_PATH=$KBS_PATH
KB_NAME=$KB_NAME
AUTO_INGEST=false
LLM_CLIENT=claude
ACTIVITY_LEVEL=0
EOF

cat >> "$KBS_PATH/log.md" <<EOF

## $TIMESTAMP | SYSTEM_CREATED | V0.115 | Path: $KBS_PATH | KB: $KB_NAME
EOF

cat > "$KBS_PATH/.gitignore" <<'EOF'
.env
*.log
*.tmp
kb/*/wiki/snapshots/
kb/*/rag-index/
EOF

# ─── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 INSTALLATION COMPLETE  ✅                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. LLM client: grant folder access to $KBS_PATH"
echo "     (Claude Desktop: Settings → Permissions → Add Folder)"
echo "  2. Optional: copy starter KB → cp -r $KBS_PATH/examples/starter-kb/wiki/topics/* $KBS_PATH/kb/$KB_NAME/wiki/topics/"
echo "  3. Verify: $KBS_PATH/scripts/status.sh"
echo "  4. In your LLM client, run the Initial Setup prompt from PROMPTS.md"
echo "  5. After every session: Follow agents.md. Close session for $KB_NAME"
echo ""
echo -e "${YELLOW}A session without a close is a session without learning.${NC}"
