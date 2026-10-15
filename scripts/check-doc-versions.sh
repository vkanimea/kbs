#!/usr/bin/env bash
# check-doc-versions.sh — ensure no doc or script hard-codes a stale version.
#
# Only VERSION, README badges and CHANGELOG should carry the version number.
# Doc titles, script descriptions and inline references must not drift.
#
# Usage:  scripts/check-doc-versions.sh
# CI:     wire into .github/workflows/validate.yml alongside the word-count guard.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

V="$(tr -d '[:space:]' < VERSION)"
bad=0

# 1. Doc H1s must not contain a V-prefixed version (README, INSTALL, docs/)
while IFS= read -r hit; do
  echo "❌ stale version in doc title: $hit"
  bad=1
done < <(grep -nE '^# .*V[0-9]+\.[0-9]+' README.md INSTALL.md docs/*.md 2>/dev/null \
          | grep -v "V${V}" || true)

# 2. First three lines of every tracked .md, .sh, .py, .ps1 (except CHANGELOG.md)
# must not contain a V-prefixed version that differs from VERSION
while IFS= read -r file; do
  [ "$file" = "CHANGELOG.md" ] && continue
  while IFS= read -r hit; do
    echo "❌ stale version in $file: $hit"
    bad=1
  done < <(head -3 "$file" | grep -nE 'V[0-9]+\.[0-9]+' | grep -v "V${V}" || true)
done < <(git ls-files '*.md' '*.sh' '*.py' '*.ps1' 2>/dev/null)

# 3. README badge must match VERSION
if ! grep -q "version-${V}" README.md 2>/dev/null; then
  echo "❌ README badge does not match VERSION=$V"
  bad=1
fi

if [ "$bad" -eq 0 ]; then
  echo "✅ All version references consistent with VERSION=$V"
fi
exit $bad