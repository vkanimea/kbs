#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Wiring test: does the instance contain everything agents.md promises to load?
#
#   tests/test-wiring.sh [INSTANCE_DIR]
#
# INSTANCE_DIR is an installed KBS instance (default: $KBS_PATH, else $HOME/kbs).
#
# WHAT THIS PROVES
#   The deterministic half of the 5-minute smoke test in docs/deployment.md:
#   every file agents.md tells the model to read actually exists, and the
#   operation table's targets are real. If a wiring doc is renamed or a
#   reference file is missing, a model told "Follow agents.md" will fail — and
#   this test fails first, deterministically, with no LLM involved.
#
# WHAT THIS DOES NOT PROVE
#   It does NOT prove a given LLM follows the rules. That is model behaviour and
#   is out of scope for a shell test (see README → Model compatibility). This
#   test only guarantees the wiring has something valid to load.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

INSTANCE="${1:-${KBS_PATH:-$HOME/kbs}}"
AGENTS="$INSTANCE/agents.md"

if [ ! -f "$AGENTS" ]; then echo "ERROR: agents.md not found: $AGENTS" >&2; exit 2; fi

PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

check_file() { # relpath  description
  if [ -f "$INSTANCE/$1" ]; then pass "$1 exists"; else fail "$1 MISSING ($2)"; fi
}

echo "KBS wiring test — $INSTANCE"
echo

# ── 1. Files agents.md says to read at session start ──────────────────────────
echo "Session-start files (agents.md → 'read CONVENTIONS.md, then SYSTEM.md'):"
check_file "CONVENTIONS.md" "named in agents.md session-start"
check_file "SYSTEM.md"      "named in agents.md session-start"
check_file "agents.md"      "the core behaviour file itself"

# ── 2. Reference files named by the operation table ──────────────────────────
echo
echo "Operation references (agents.md → 'Operations' table):"
for ref in session-close ingestion chat-input failures actions health-check \
           journal learning; do
  check_file "reference/$ref.md" "target of the operation table"
done

# ── 3. The literal loading trigger is present ────────────────────────────────
echo
echo "Loading contract:"
if grep -q "Follow agents.md" "$INSTANCE/PROMPTS.md" 2>/dev/null || \
   grep -rq "Follow agents.md" "$INSTANCE/reference/" 2>/dev/null; then
  pass "'Follow agents.md' trigger documented"
else
  fail "'Follow agents.md' trigger not found in PROMPTS.md or reference/"
fi

if grep -q "## The 11 Rules" "$AGENTS"; then
  pass "agents.md contains the 11 Rules section"
else
  fail "agents.md is missing the '## The 11 Rules' section"
fi

# ── 4. The scripts the smoke test relies on ──────────────────────────────────
echo
echo "Smoke-test scripts:"
for s in status.sh kbs-lint.sh kbs-sync.sh doctor.sh; do
  if [ -x "$INSTANCE/scripts/$s" ] || [ -f "$INSTANCE/scripts/$s" ]; then
    pass "scripts/$s present"
  else
    fail "scripts/$s MISSING (smoke test / close will fail)"
  fi
done

# ── 5. The client-wiring doc exists (so the instructions are findable) ───────
echo
echo "Documentation:"
check_file "docs/deployment.md" "per-client wiring table lives here"

echo
printf 'wiring: %d ok, %d fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
echo "Wiring is complete — a model told 'Follow agents.md' has valid files to load."
echo "(This does not prove the model follows them — see README → Model compatibility.)"
