#!/bin/bash
# Knowledge Base System (KBS) — Linux/macOS Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash
#   KBS_PATH=/custom/path KB_NAME=myproject ./install.sh
#   KBS_REF=<tag> ./install.sh         # pin to a specific tag
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

# Version — read from the repo's VERSION file so this script never drifts from the release.
# If KBS_REF is set, fetch from that tag instead of main.
REF="${KBS_REF:-main}"
VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION" 2>/dev/null || true)"
if [ -z "$VERSION" ] && [ -n "$SCRIPT_DIR" ] && command -v curl &>/dev/null; then
  VERSION="$(curl -fsSL "${REPO_URL/main/$REF}/VERSION" 2>/dev/null | tr -d '[:space:]' || true)"
fi
# Fallback to 'unknown' instead of a stale hard-coded version
VERSION="${VERSION:-unknown}"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
printf '║%-62s║\n' "       Knowledge Base System (KBS) V$VERSION Installer"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# If version is unknown, warn the user
if [ "$VERSION" = "unknown" ]; then
  echo -e "${YELLOW}⚠️  Could not determine version from repo — install may be from unpinned source${NC}"
fi

echo -e "${YELLOW}📍 Path : $KBS_PATH${NC}"
echo -e "${YELLOW}📚 KB   : $KB_NAME${NC}"
echo ""

# ─── Directories ───────────────────────────────────────────────────────────────
mkdir -p "$KBS_PATH"/{reference,scripts/windows,scripts/analyze-sessions,docs}
mkdir -p "$KBS_PATH/kb/$KB_NAME"/{raw/chat-transcripts,raw-assets/{pdfs,images},wiki/{topics,snapshots},outputs}
echo -e "${GREEN}✅ Directories created${NC}"

# Detect fresh install vs upgrade (for the audit log event name)
if [ -f "$KBS_PATH/log.md" ]; then INSTANCE_EXISTED=1; else INSTANCE_EXISTED=0; fi

# ─── File installer: local copy if available, else download; abort on failure ──
# System-owned templates — refreshed on every install/upgrade
SYSTEM_TEMPLATES=(agents.md PROMPTS.md CONVENTIONS.md)
# User-owned files — seeded only when absent, NEVER overwritten (your content lives here)
USER_FILES=(SYSTEM.md DECISIONS.md INBOX.md CHAT_INBOX.md FAILURES.md SUCCESSES.md CAREER.md ACTIONS.md JOURNAL.md log.md)
REFERENCES=(session-close.md ingestion.md chat-input.md failures.md successes.md actions.md journal.md learning.md session-analysis.md writing-style.md health-check.md atoms.md)
SCRIPTS=(chat-adapter.sh chat-api-adapter.py health-check.sh status.sh auto-close.sh due-actions.sh topic-index.sh youtube-ingest.sh hourly-ingest.sh rag.py rag-index.sh rag-query.sh nightly-backup.sh git-credential-env.sh goal-loop.sh graphify-index.sh kbs-sync.sh kbs-drift-check.sh model-config.sh kbs-lint.sh ingest-freshness.sh staleness-sweep.sh kbs-provenance.sh backup-catchup.sh backup-verify.sh)

# SHA256SUMS support (optional) — if present in repo at the pinned REF, verify downloads
SHA256SUMS_URL="${REPO_URL/main/$REF}/SHA256SUMS"
SHA256SUMS_FILE=""
if command -v curl &>/dev/null; then
  SHA256SUMS_FILE=$(curl -fsSL "$SHA256SUMS_URL" 2>/dev/null || true)
fi

download() {
  local dest="$1"
  local relpath="$2"
  local url="${REPO_URL/main/$REF}/$relpath"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$relpath" ]; then
    cp "$SCRIPT_DIR/$relpath" "$dest"
  else
    curl -fsSL "$url" -o "$dest" || { echo -e "${RED}❌ Failed to download $relpath${NC}"; exit 1; }
  fi
  # Verify checksum if SHA256SUMS available
  if [ -n "$SHA256SUMS_FILE" ]; then
    expected=$(echo "$SHA256SUMS_FILE" | grep " $relpath$" | awk '{print $1}')
    if [ -n "$expected" ]; then
      actual=$(sha256sum "$dest" | awk '{print $1}')
      if [ "$actual" != "$expected" ]; then
        echo -e "${RED}❌ Checksum mismatch for $relpath (expected $expected, got $actual)${NC}"
        exit 1
      fi
    fi
  fi
}

# System templates (always refresh)
for f in "${SYSTEM_TEMPLATES[@]}"; do
  download "$KBS_PATH/$f" "templates/$f"
done
echo -e "${GREEN}✅ System templates installed${NC}"

# User files (seed only)
for f in "${USER_FILES[@]}"; do
  [ -f "$KBS_PATH/$f" ] || download "$KBS_PATH/$f" "templates/$f"
done
echo -e "${GREEN}✅ User files seeded${NC}"

# References
mkdir -p "$KBS_PATH/reference"
for f in "${REFERENCES[@]}"; do
  download "$KBS_PATH/reference/$f" "templates/reference/$f"
done
echo -e "${GREEN}✅ Reference modules installed${NC}"

# Scripts
mkdir -p "$KBS_PATH/scripts"
mkdir -p "$KBS_PATH/scripts/windows"
mkdir -p "$KBS_PATH/scripts/analyze-sessions"
for f in "${SCRIPTS[@]}"; do
  download "$KBS_PATH/scripts/$f" "scripts/$f"
  chmod +x "$KBS_PATH/scripts/$f" 2>/dev/null || true
done
echo -e "${GREEN}✅ Scripts installed${NC}"

# Docs
mkdir -p "$KBS_PATH/docs"
for f in architecture.md backup-and-restore.md connector-hygiene.md deployment.md glossary.md goal-spec.md input-output-guide.md security.md swot-analysis.md user-guide.md version-advising.md; do
  [ -f "$KBS_PATH/docs/$f" ] || download "$KBS_PATH/docs/$f" "docs/$f"
done
echo -e "${GREEN}✅ Docs installed${NC}"

# Ensure .gitignore
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/.gitignore" ]; then
  cp "$SCRIPT_DIR/.gitignore" "$KBS_PATH/.gitignore"
elif command -v curl &>/dev/null; then
  curl -fsSL "${REPO_URL/main/$REF}/.gitignore" -o "$KBS_PATH/.gitignore" 2>/dev/null || true
fi

# Ensure .env.template
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/.env.template" ]; then
  cp "$SCRIPT_DIR/.env.template" "$KBS_PATH/.env.template"
elif command -v curl &>/dev/null; then
  curl -fsSL "${REPO_URL/main/$REF}/.env.template" -o "$KBS_PATH/.env.template" 2>/dev/null || true
fi

# Ensure VERSION file
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/VERSION" ]; then
  cp "$SCRIPT_DIR/VERSION" "$KBS_PATH/VERSION"
elif command -v curl &>/dev/null; then
  curl -fsSL "${REPO_URL/main/$REF}/VERSION" -o "$KBS_PATH/VERSION" 2>/dev/null || true
fi

# Ensure SHA256SUMS if available
if [ -n "$SHA256SUMS_FILE" ] && [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SHA256SUMS" ]; then
  cp "$SCRIPT_DIR/SHA256SUMS" "$KBS_PATH/SHA256SUMS"
elif [ -n "$SHA256SUMS_FILE" ] && command -v curl &>/dev/null; then
  echo "$SHA256SUMS_FILE" > "$KBS_PATH/SHA256SUMS"
fi

# Credential helper registration (idempotent)
git -C "$KBS_PATH" config credential.helper '!bash scripts/git-credential-env.sh' 2>/dev/null || true

# Log the event
if [ "$INSTANCE_EXISTED" -eq 1 ]; then
  EVENT="UPGRADE"
else
  EVENT="INSTALL"
fi
echo "## $TIMESTAMP | $EVENT | V$VERSION" >> "$KBS_PATH/log.md"
echo "- Path: $KBS_PATH" >> "$KBS_PATH/log.md"
echo "- KB: $KB_NAME" >> "$KBS_PATH/log.md"
[ "$INSTANCE_EXISTED" -eq 1 ] && echo "- Upgraded from previous version" >> "$KBS_PATH/log.md"
echo "" >> "$KBS_PATH/log.md"

echo -e "${GREEN}✅ Install/upgrade complete — KBS V$VERSION ready at $KBS_PATH${NC}"
echo -e "${CYAN}Next steps:${NC}"
echo "  cd $KBS_PATH"
echo "  cp .env.template .env    # add your tokens"
echo "  git init && git add -A && git commit -m 'KBS initial commit'"
echo "  git remote add origin <your-private-repo>"
echo "  git push -u origin main"