#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Behavioural regression tests for the KBS checkers.
#
#   tests/test-checkers.sh [INSTANCE_DIR]
#
# INSTANCE_DIR is an installed KBS instance whose scripts/ dir is exercised
# (default: $KBS_PATH, else $HOME/kbs). CI passes the freshly-installed test
# instance; locally pass your own ~/kbs or any throwaway copy.
#
# These are BEHAVIOURAL tests, not shape checks. validate.yml already proves a
# fresh install lints clean; that does NOT prove the checkers are correct. Both
# scripts below were once wrong in opposite directions (a false positive that
# blocked a valid edit, and a false "overdue" alarm on a deliberately-deferred
# item). Each case here corresponds to a real bug, so it cannot silently return.
#
# Every case asserts in BOTH directions:
#   - things that MUST error/flag
#   - things that MUST NOT error/flag
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail

INSTANCE="${1:-${KBS_PATH:-$HOME/kbs}}"
LINT="$INSTANCE/scripts/kbs-lint.sh"
DUE="$INSTANCE/scripts/due-actions.sh"

if [ ! -x "$LINT" ]; then echo "ERROR: not found/executable: $LINT" >&2; exit 2; fi
if [ ! -x "$DUE" ]; then echo "ERROR: not found/executable: $DUE" >&2; exit 2; fi

PASS=0
FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ✅ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ❌ $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── kbs-lint.sh: ACTIONS.md cases ────────────────────────────────────────────
# lint ACTIONS.md content -> echo the number of errors reported
lint_actions() {
  local dir="$WORK/lint-$$-$RANDOM"
  mkdir -p "$dir"
  printf '%b\n' "$1" > "$dir/ACTIONS.md"
  # minimal scaffolding so the linter has the instance shape it expects
  : > "$dir/DECISIONS.md"; : > "$dir/FAILURES.md"
  : > "$dir/SUCCESSES.md"; : > "$dir/INBOX.md"
  : > "$dir/CHAT_INBOX.md"; : > "$dir/log.md"
  bash "$LINT" "$dir" --quiet 2>/dev/null | grep -c 'ERROR' || true
}

echo "── kbs-lint.sh — ACTIONS.md ──"

# A bold value that runs to end-of-line must NOT read as empty.
# Regression: greedy /^.*\*\*[^*]*\*\*/ in inline_value() swallowed the value.
ACTIONS_HEAD='# ACTIONS\n\n## Open Actions\n\n## Completed Actions'
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case A — bold phrase ends the line (was FALSE POSITIVE)
**Decided:** x
**Why:** y
**Due:** today
**Done:** Yes
**Outcome:** **Closed for now — deferred.**")
[ "$N" -eq 0 ] && ok "bold Outcome ending the line does not read as empty" \
              || bad "bold Outcome ending the line reported $N error(s) — false positive returned"

# Unbolded tail after a bold phrase — must also pass.
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case B — unbolded tail after bold phrase
**Decided:** x
**Why:** y
**Due:** today
**Done:** Yes
**Outcome:** **Closed — deferred.** Extra unbolded prose follows here.")
[ "$N" -eq 0 ] && ok "bold phrase followed by plain text passes" \
              || bad "bold phrase followed by plain text reported $N error(s)"

# Plain, no bold at all.
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case C — plain Outcome
**Decided:** x
**Why:** y
**Due:** today
**Done:** Yes
**Outcome:** Closed — plain text to the end of the line.")
[ "$N" -eq 0 ] && ok "plain Outcome passes" \
              || bad "plain Outcome reported $N error(s)"

# Done with a genuinely empty Outcome MUST still error (the check must not be weakened).
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case D — genuinely empty Outcome must ERROR
**Decided:** x
**Why:** y
**Due:** today
**Done:** Yes
**Outcome:**")
[ "$N" -ge 1 ] && ok "genuinely empty Outcome still errors" \
              || bad "genuinely empty Outcome was NOT caught — check was weakened"

# Done with no Outcome field at all MUST still error.
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case F — no Outcome field must ERROR
**Decided:** x
**Why:** y
**Due:** today
**Done:** Yes")
[ "$N" -ge 1 ] && ok "missing Outcome field still errors" \
              || bad "missing Outcome field was NOT caught — check was weakened"

# An open (Done: No) entry needs no Outcome and must pass.
N=$(lint_actions "$ACTIONS_HEAD

## 2026-01-01 | Case G — open entry, no Outcome required
**Decided:** x
**Why:** y
**Due:** next session
**Done:** No
**Outcome:**")
[ "$N" -eq 0 ] && ok "open entry without Outcome passes" \
              || bad "open entry reported $N error(s)"

# ── due-actions.sh: deferral annotations must not create deadlines ────────────
echo "── due-actions.sh — deferred / on-hold / dated ──"

# run_due ACTIONS.md content -> "overdue:|titles"
run_due() {
  local dir="$WORK/due-$$-$RANDOM"
  mkdir -p "$dir"
  printf '%b\n' "$1" > "$dir/ACTIONS.md"
  : > "$dir/log.md"
  KBS_PATH="$dir" bash "$DUE" 2>/dev/null
}

PAST="2026-10-11"

OUT=$(run_due "# ACTIONS

## Open Actions

## 2026-01-01 | TRULY OVERDUE — dated deadline in the past
**Decided:** x
**Why:** y
**Due:** $PAST
**Done:** No
**Outcome:**

## Completed Actions")
echo "$OUT" | grep -q 'TRULY OVERDUE' && ok "dated past deadline is still flagged overdue" \
                                      || bad "dated past deadline was NOT flagged — regression"

OUT=$(run_due "# ACTIONS

## Open Actions

## 2026-01-01 | Deferred with a date — must NOT be overdue
**Decided:** x
**Why:** y
**Due:** unscheduled (deferred by owner $PAST)
**Done:** No
**Outcome:**

## Completed Actions")
echo "$OUT" | grep -q 'Deferred with a date' \
  && bad "deferral date was parsed as a deadline — nagging returned" \
  || ok "deferral annotation does not create a deadline"

OUT=$(run_due "# ACTIONS

## Open Actions

## 2026-01-01 | On hold with a date — must NOT be overdue
**Decided:** x
**Why:** y
**Due:** unscheduled (on hold since 2026-09-16)
**Done:** No
**Outcome:**

## Completed Actions")
echo "$OUT" | grep -q 'On hold with a date' \
  && bad "'on hold' date was parsed as a deadline" \
  || ok "'on hold' annotation does not create a deadline"

# The "prefer the LAST date" rule must survive: re-dated annotations ARE deadlines.
OUT=$(run_due "# ACTIONS

## Open Actions

## 2026-01-01 | Re-dated annotation — LAST date is the live deadline
**Decided:** x
**Why:** y
**Due:** awaiting partner (re-dated from 2026-01-01)
**Done:** No
**Outcome:**

## Completed Actions")
echo "$OUT" | grep -q 'Re-dated annotation' && ok "re-dated annotation still treated as a deadline (no regression)" \
                                          || bad "re-dated annotation stopped being flagged — over-corrected"

# A future deadline must NOT be flagged as overdue.
OUT=$(run_due "# ACTIONS

## Open Actions

## 2026-01-01 | Future deadline — must NOT be overdue
**Decided:** x
**Why:** y
**Due:** 2999-01-01
**Done:** No
**Outcome:**

## Completed Actions")
echo "$OUT" | grep -q 'Future deadline' && bad "a future deadline was flagged overdue" \
                                        || ok "future deadline is not flagged overdue"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "checker tests: $PASS passed, 0 failed"
  exit 0
fi
echo "checker tests: $PASS passed, $FAIL FAILED"
exit 1