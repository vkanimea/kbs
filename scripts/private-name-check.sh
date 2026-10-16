#!/usr/bin/env bash
# private-name-check.sh — scan for instance-specific names that must not leak into public files.
#
# This script is intentionally NOT shipped to data repos. It lives only in the
# system repo (the public one) so the exact patterns it guards are not published.
# The CI step in .github/workflows/validate.yml runs this check.
#
# Usage:  scripts/private-name-check.sh
# CI:     .github/workflows/validate.yml
# Env:    KBS_PRIVATE_PATTERNS (required) — space-separated patterns to scan for

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# On a FORK PR there is no secret available, so skip is expected and correct.
# On any other run (push to main, same-repo PR, workflow_dispatch) an empty
# KBS_PRIVATE_PATTERNS means the guard has silently gone missing — that is a
# FAIL-CLOSED condition, not a skip: a deleted/mistyped secret must not turn
# the private-name guard off without failing.
IS_FORK="${IS_FORK:-false}"
if [ -z "${KBS_PRIVATE_PATTERNS:-}" ]; then
  if [ "$IS_FORK" = "true" ]; then
    echo "⏭️  KBS_PRIVATE_PATTERNS not set (fork PR — no secret) — skipping private-name check"
    exit 0
  fi
  echo "❌ KBS_PRIVATE_PATTERNS is not set but this is not a fork PR — private-name guard requires a secret; fail closed" >&2
  exit 1
fi

# Split space-separated env var into array
read -ra PATTERNS <<< "$KBS_PRIVATE_PATTERNS"

if [ "${#PATTERNS[@]}" -eq 0 ]; then
  echo "❌ KBS_PRIVATE_PATTERNS is empty — cannot run without patterns" >&2
  exit 1
fi

echo "Checking for instance-specific names in public files..."
bad=0

for pattern in "${PATTERNS[@]}"; do
  # Use grep -r so this works outside a git checkout (e.g., extracted ZIP in CI)
  # Exclude this script, CHANGELOG (historical), version-advising.md, and .git
  if grep -rIn --exclude-dir=.git --exclude=private-name-check.sh --exclude=CHANGELOG.md --exclude=version-advising.md "$pattern" . 2>/dev/null; then
    echo "❌ Found '$pattern' in public files (see matches above)"
    bad=1
  fi
done

if [ "$bad" -eq 0 ]; then
  echo "✅ No instance-specific names found in public files"
fi
exit $bad