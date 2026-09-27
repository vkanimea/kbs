#!/bin/bash
# goal-loop.sh — KBS agentic goal-loop orchestrator (pi). V0.116
#
# Implements a persistent "Ralph / /goal" loop on pi WITHOUT a pi built-in:
#   loop { run pi with the objective + progress -> apply changes
#          run the validation command -> if pass, done; else feed failures back }
#
# This is a Pattern-A wrapper (deterministic control) over pi's agent loop.
# The goal *contract* + how to write it lives in the Pattern-B skill:
#   ~/.pi/agent/skills/goal-loop/SKILL.md
#
# Usage:
#   goal-loop.sh <goalspec.md> [max_iterations]
#
# A goal spec is a small markdown file with this template (see docs/goal-spec.md):
#
#   ---
#   objective: One concrete outcome.
#   read_first: "src/, tests/, PLAN.md"
#   constraints: "no public API changes; no new deps"
#   validate:   "pytest -q"          # exact shell command proving progress
#   stop_when:  "pytest -q"          # exact command that signals done
#   max_iter:   8
#   ---
#   Optional free-text brief beyond the frontmatter.
#
# Exit codes:
#   0 = validation command passed (goal met / upstream simudd)
#   1 = loop exhausted max iterations without passing
#   2 = goal spec missing/invalid
#   3 = pi invocation failed (provider/auth) — run again once wired

set -uo pipefail

KBS="${KBS:-$HOME/kbs}"
PI_BIN="${PI_BIN:-pi}"
# Provider wiring (configurable via env; defaults to the project's wired openrouter)
PI_PROVIDER="${PI_PROVIDER:-openrouter}"
PI_MODEL="${PI_MODEL:-deepseek/deepseek-v4-flash-0731}"
SPEC="${1:?usage: goal-loop.sh <goalspec.md> [max_iterations]}"
MAX_ITER="${2:-$(awk -F: '/^max_iter:/{gsub(/[[:space:]]/,"",$2); print $2}' "$SPEC" 2>/dev/null || echo 8)}"
: "${MAX_ITER:=8}"

if [ ! -f "$SPEC" ]; then
  echo "ERROR: goal spec not found: $SPEC" >&2; exit 2
fi

yaml(){
  awk -F: "/^${1}:/{
    sub(/^[^:]*:[[:space:]]*/,\"\");
    sub(/[[:space:]]+#.*$/,\"\");      # drop trailing comment
    gsub(/^[\"']/,\"\"); gsub(/[\"']$/,\"\");  # strip one pair of surrounding quotes
    sub(/[[:space:]]+$/,\"\");
    print
  }" "$SPEC"
}
OBJECTIVE="$(yaml objective)"; READ_FIRST="$(yaml read_first)"
CONSTRAINTS="$(yaml constraints)"; VALIDATE="$(yaml validate)"; STOP="$(yaml stop_when)"
[ -z "$OBJECTIVE" ] && { echo "ERROR: spec missing 'objective'" >&2; exit 2; }
[ -z "$VALIDATE" ]  && { echo "ERROR: spec missing 'validate'"   >&2; exit 2; }
STOP="${STOP:-$VALIDATE}"

PROGRESS_LOG="$KBS/journal/goal-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$PROGRESS_LOG")"
log(){ echo "[goal-loop] $*" | tee -a "$PROGRESS_LOG"; }

# The prompt given to pi on each iteration. Includes objective, constraints,
# progress + last failures, and instructs pi to edit then ASK for validation.
prompt_for_iter(){
  local iter="$1" failures="$2"
  cat <<EOF
Work autonomously on this goal.

OBJECTIVE: ${OBJECTIVE}

Your final output MUST satisfy the validation command. Do not stop claiming done
until you have actually run the validation command and it passes.

${CONSTRAINTS:+CONSTRAINTS (do not violate): ${CONSTRAINTS}}
${READ_FIRST:+READ FIRST: ${READ_FIRST}}

PROGRESS:
- iteration ${iter} / ${MAX_ITER}
$(printf '%s\n' "$failures" | sed 's/^/- /')

ACTION REQUIRED THIS TURN:
1. Read the files listed in READ FIRST (and plan as needed).
2. Make the smallest change that moves the validation command toward passing.
3. Run the validation command yourself if you can, and state its exact output.
4. Report: what changed, the exact validation output, and anything blocking you.
EOF
}

iter=1; failures=""
while [ "$iter" -le "$MAX_ITER" ]; do
  log "=== iteration ${iter}/${MAX_ITER} ==="
  PROMPT="$(prompt_for_iter "$iter" "$failures")"
  log "invoking pi --
  $PROMPT"

  # Run pi once. Timeout guards against a hang; provider/model passed via env.
  if ! OUT="$("$PI_BIN" --print --provider "$PI_PROVIDER" --model "$PI_MODEL" "$PROMPT" 2>&1)"; then
    log "pi invocation failed (rc=$?) — provider/auth? output:"
    printf '%s\n' "$OUT" | tail -n 5 >> "$PROGRESS_LOG"
    echo "ERROR: pi failed to run (rc=$?). Is your model/provider wired? (provider=$PI_PROVIDER model=$PI_MODEL)" >&2
    exit 3
  fi

  # Run the validation gate. If it passes, the goal is met.
  # Use bash -c (not eval) so shell-test syntax like `[ ... ]` and `$(...)` works.
  log "validation: ${VALIDATE}"
  if bash -c "${VALIDATE}" >> "$PROGRESS_LOG" 2>&1; then
    printf 'GOAL MET: validation passed on iteration %s.\n' "$iter"
    printf '\n--- final pi output ---\n'; printf '%s\n' "$OUT"
    exit 0
  fi

  # Capture failures and feed them back next iteration.
  failures="$( { echo "--- validation failures, iteration $iter ---";
                  bash -c "${VALIDATE}" 2>&1 | head -n 40; } )"
  log "validation FAILED; failures appended for next iteration."
  iter=$((iter+1))
done

echo "ERROR: goal not met after ${MAX_ITER} iterations. See $PROGRESS_LOG" >&2
exit 1
