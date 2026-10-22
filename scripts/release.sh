#!/usr/bin/env bash
# release.sh — generate SHA256SUMS for the current release tag
#
# Usage: scripts/release.sh [TAG]
#   TAG defaults to the VERSION file content prefixed with 'v' (e.g., v0.126)
#
# This script generates SHA256SUMS in the repo root for all files that are
# downloaded by install.sh / install.ps1. The installers will verify downloads
# against this file when KBS_REF is pinned to a tag.
#
# Run this AFTER tagging a release:
#   git tag v0.126
#   scripts/release.sh v0.126

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-v$(cat VERSION 2>/dev/null || echo unknown)}"

if [ "$TAG" = "vunknown" ]; then
  echo "❌ Cannot determine version from VERSION file"
  exit 1
fi

echo "Generating SHA256SUMS for tag $TAG..."

# Files that install.sh / install.ps1 download (relative to repo root)
FILES=(
  "install.sh"
  "install.ps1"
  "VERSION"
  "CHANGELOG.md"
  "agents.md"
  "PROMPTS.md"
  "CONVENTIONS.md"
  "SYSTEM.md"
  "DECISIONS.md"
  "INBOX.md"
  "CHAT_INBOX.md"
  "FAILURES.md"
  "SUCCESSES.md"
  "CAREER.md"
  "ACTIONS.md"
  "JOURNAL.md"
  "log.md"
  "scripts/chat-adapter.sh"
  "scripts/chat-api-adapter.py"
  "scripts/health-check.sh"
  "scripts/status.sh"
  "scripts/auto-close.sh"
  "scripts/due-actions.sh"
  "scripts/topic-index.sh"
  "scripts/youtube-ingest.sh"
  "scripts/hourly-ingest.sh"
  "scripts/git-credential-env.sh"
  "scripts/nightly-backup.sh"
  "scripts/rag.py"
  "scripts/rag-index.sh"
  "scripts/rag-query.sh"
  "scripts/goal-loop.sh"
  "scripts/graphify-index.sh"
  "scripts/kbs-sync.sh"
  "scripts/kbs-drift-check.sh"
  "scripts/model-config.sh"
  "scripts/kbs-lint.sh"
  "scripts/kbs-provenance.sh"
  "scripts/backup-catchup.sh"
  "scripts/backup-verify.sh"
  "scripts/doctor.sh"
  "scripts/private-name-check.sh"
  "scripts/release.sh"
  "scripts/analyze-sessions/sessions.py"
  "scripts/analyze-sessions/cost.py"
  "scripts/analyze-sessions/prompts.py"
  "scripts/analyze-sessions/search.py"
  "scripts/analyze-sessions/show_session.py"
  "scripts/analyze-sessions/README.md"
  "scripts/windows/status.ps1"
  "scripts/windows/health-check.ps1"
  "scripts/windows/auto-close.ps1"
  "scripts/windows/due-actions.ps1"
  "scripts/windows/topic-index.ps1"
  "scripts/windows/youtube-ingest.ps1"
  "scripts/windows/hourly-ingest.ps1"
  "scripts/windows/kbs-lint.ps1"
  "scripts/windows/kbs-provenance.ps1"
  "scripts/windows/backup-catchup.ps1"
  "scripts/windows/backup-verify.ps1"
  "scripts/windows/private-name-check.ps1"
  "scripts/windows/release.ps1"
  "templates/agents.md"
  "templates/PROMPTS.md"
  "templates/CONVENTIONS.md"
  "templates/SYSTEM.md"
  "templates/DECISIONS.md"
  "templates/INBOX.md"
  "templates/CHAT_INBOX.md"
  "templates/FAILURES.md"
  "templates/SUCCESSES.md"
  "templates/CAREER.md"
  "templates/ACTIONS.md"
  "templates/JOURNAL.md"
  "templates/log.md"
  "templates/reference/session-close.md"
  "templates/reference/ingestion.md"
  "templates/reference/chat-input.md"
  "templates/reference/failures.md"
  "templates/reference/successes.md"
  "templates/reference/actions.md"
  "templates/reference/journal.md"
  "templates/reference/learning.md"
  "templates/reference/session-analysis.md"
  "templates/reference/writing-style.md"
  "templates/reference/health-check.md"
  "docs/architecture.md"
  "docs/backup-and-restore.md"
  "docs/deployment.md"
  "docs/glossary.md"
  "docs/goal-spec.md"
  "docs/input-output-guide.md"
  "docs/security.md"
  "docs/swot-analysis.md"
  "docs/user-guide.md"
  "docs/version-advising.md"
  "examples/starter-kb/kb/main/wiki/topics/example.md"
  "examples/starter-kb/kb/main/raw/chat-transcripts/example.md"
  "examples/starter-kb/.gitignore"
)

# Filter to only existing files
EXISTING_FILES=()
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    EXISTING_FILES+=("$f")
  fi
done

if [ "${#EXISTING_FILES[@]}" -eq 0 ]; then
  echo "❌ No files found to checksum"
  exit 1
fi

# Generate SHA256SUMS
sha256sum "${EXISTING_FILES[@]}" > SHA256SUMS

echo "✅ SHA256SUMS generated with ${#EXISTING_FILES[@]} files"
echo ""
echo "To use with installers:"
echo "  git add SHA256SUMS"
echo "  git commit -m \"chore: add SHA256SUMS for $TAG\""
echo "  git push && git push --tags"
echo ""
echo "Then users can verify with:"
echo "  KBS_REF=$TAG ./install.sh"
echo "  \$env:KBS_REF=\"$TAG\"; .\\install.ps1"