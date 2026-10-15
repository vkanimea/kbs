#!/usr/bin/env bash
# private-name-check.sh — scan for instance-specific names that must not leak into public files.
#
# This script is intentionally NOT shipped to data repos. It lives only in the
# system repo (the public one) so the exact patterns it guards are not published.
# The CI step in .github/workflows/validate.yml runs this check.
#
# Usage:  scripts/private-name-check.sh
# CI:     .github/workflows/validate.yml

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bad=0

# Patterns that identify the owner's infrastructure — keep this list private.
# If you add a pattern here, also update docs/backup-and-restore.md and
# templates/reference/actions.md to use generic placeholders.
PATTERNS=(
  "harbor01"
  "pi-state"
  "pi-hermes"
  "session-hoarder"
  "git.dustybranch.com"
  "GITEA_USERNAME"
  "GITEA_PASSWORD"
  "SPC"
  "SPC_PCCOS"
)

echo "Checking for instance-specific names in public files..."
for pattern in "${PATTERNS[@]}"; do
  # Exclude this script itself and CHANGELOG (historical record)
  if git grep -n "$pattern" -- ':!scripts/private-name-check.sh' ':!CHANGELOG.md' ':!docs/version-advising.md' 2>/dev/null | grep -v "Binary file"; then
    echo "❌ Found '$pattern' in tracked files (see matches above)"
    bad=1
  fi
done

if [ "$bad" -eq 0 ]; then
  echo "✅ No instance-specific names found in public files"
fi
exit $bad