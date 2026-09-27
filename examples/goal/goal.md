---
objective: Add a stdlib-only goal_ok() helper test to scripts/that passes.
read_first: "~/kbs/scripts/rag.py, tests/ if present"
constraints: "stdlib only; no new files outside scripts/ and tests/; don't touch backup logic"
validate:   "true"  # REPLACE with your real gate, e.g. "pytest -q"
stop_when:  "true"
max_iter:   3
---
# Example goal: self-test the wrapper
Replace the `validate` with a real command. This file exists so you can test the
loop mechanism with `PI_BIN=/path/to/fake ./goal-loop.sh examples/goal.md`.
