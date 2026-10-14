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

# 1. Doc H1s must not contain a V-prefixed version
while IFS= read -r hit; do
  echo "❌ stale version in doc title: $hit"; bad=1
done < <(grep -nE '^# .*V[0-9]+\.[0-9]+' README.md INSTALL.md docs/*.md 2>/dev/null \
          | grep -v "V${V}" || true)

# 2. Script descriptions must not contain a stale V-prefixed version
while IFS= read -r hit; do
  echo "❌ stale version in script: $hit"; bad=1
done < <(grep -rnE 'description=.*V[0-9]+\.[0-9]+' scripts 2>/dev/null \
          | grep -v "V${V}" || true)

# 3. Python argparse descriptions
while IFS= read -r hit; do
  echo "❌ stale version in script: $hit"; bad=1
done < <(grep -rnE 'description=.*V[0-9]+\.[0-9]+' scripts 2>/dev/null \
          | grep -v "V${V}" || true)

# 4. Docstring version lines
while IFS= read -r hit; do
  echo "❌ stale version in docstring: $hit"; bad=1
done < <(grep -rnE '— V[0-9]+\.[0-9]+' scripts/*.py 2>/dev/null \
          | grep -v "V${V}" || true)

if [ "$bad" -eq 0 ]; then
  echo "✅ All version references consistent with VERSION=$V"
fi
exit $bad
