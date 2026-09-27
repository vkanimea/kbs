# Goal Spec Format — for the goal-loop wrapper (`goal-loop.sh`)

Write one goal per markdown file. pi's goal-loop wrapper (`goal-loop.sh`) reads the
frontmatter; the body is a free-text brief pi reads for extra context.

```markdown
---
objective: One concrete, check-able outcome in one sentence.
read_first: "src/, tests/, PLAN.md, README.md"
constraints: "no public API changes; no new dependencies; keep imports compatible"
validate:   "pytest -q"            # exact shell command proving progress (must run)
stop_when:  "pytest -q"            # exact command that signals DONE (defaults to validate)
max_iter:   8                       # loop budget (default 8)
---
Optional free-text brief. Tell pi extra context the frontmatter can't hold.
```

## Field guide

| Field | Required | Meaning |
|---|---|---|
| `objective` | yes | One sentence, one concrete outcome. No vague "improve this". |
| `read_first` | yes-ish | Files/dirs pi must read first. "(optional)" if nothing. |
| `constraints` | no | What must NOT change (API, files, libs, conventions). |
| `validate` | yes | **Exact shell command** that must exit 0 for the goal to be met. Keep it simple (`pytest -q`, `./check.sh`). For complex logic put it in a helper script and reference it. |
| `stop_when` | no | Condition signalling done; equals `validate` if omitted. |
| `max_iter` | no | Loop budget; wrapper default 8. |

## Rules of thumb (from Ondrej's goal-loop contract)
- **Keep `validate` a simple command.** The wrapper parses the YAML value plainly; avoid embedded quotes/backslashes in the command string. If the gate is more than ~a one-liner, write a helper script (e.g. `scripts/check-goal.sh`) and reference it. This is the robust, tested pattern.
- **Stop condition must be verifiable**: a passing test/build/coverage/eval, not "done".
- **Constraints are non-negotiables** — they are checked implicitly by the validate gate.
- **No minimum duration**: any repeated autonomous task with a defined "done" fits.
- **Bad fits**: exploratory work, vague goals, prod-destructive or shared-infra ops,
  anything without a "done" definition. Use a normal prompt instead.

## Examples

### Good — a migration
```markdown
---
objective: Migrate this repo from Pydantic v1 to v2 without behavior change.
read_first: "pyproject.toml, src/, tests/"
constraints: "no public API changes; keep backwards-compat via shims; no new deps"
validate:   "pytest -q"
---
Migrate all imports and deprecated calls. Run the suite until green.
```

### Bad — not a goal
```markdown
objective: Make the code better.                       # not verifiable
validate:   "echo done"                                # hardcoded-pass, not a real gate
```

## Running
```bash
~/kbs/scripts/goal-loop.sh path/to/goal.md          # default budget
~/kbs/scripts/goal-loop.sh path/to/goal.md 12       # custom budget
```
Exit 0 = goal met; 1 = exhausted budget; 2 = bad spec; 3 = pi couldn't run.
