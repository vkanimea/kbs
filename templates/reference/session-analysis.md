# Reference: Session Analysis (V0.117)

Loaded when the owner runs one of:

- `Follow agents.md. Analyze sessions for [KB]` — full pass (cost + patterns + struggles)
- `Follow agents.md. What did my sessions cost for [KB]?` — cost rollup only
- `Follow agents.md. Mine my prompts for [KB]` — prompt-pattern mining only

This operation turns **your own agent history** into KBS input. Where ingestion reads
documents and journal operations read reflection, session analysis reads what you actually
did with the agent: what it cost, what you repeatedly asked for, where it struggled. The
output is **captures**, not wiki claims — it flows through the normal INBOX pipeline.

Read-only over `~/.pi/agent/sessions/`. It never writes to the session store.

---

## What This Reads

Pi stores sessions as JSONL under `~/.pi/agent/sessions/<project-slug>/*.jsonl`.
Assistant messages carry `usage.cost` (already split into input/output/cacheRead/
cacheWrite/total), so cost analysis is a sum. Subagent transcripts live nested inside
the parent session's directory.

Helper scripts ship with KBS at `scripts/analyze-sessions/` (pure stdlib Python 3, no
deps). They are read-only.

| Script | Answers |
|---|---|
| `cost.py` | How much did I spend — total, by day, project, model, or session |
| `prompts.py` | What do I keep asking? (prompt-pattern mining) |
| `search.py` | Where did I discuss X across all transcripts? |
| `show_session.py` | Render one session as markdown (drill-down) |

Shared filters on all four: `--since 7d` / `--until`, `--cwd`, `--model`, `--session`,
`--errors-only`, `--grep`. Run them with `python3`.

---

## Procedure

### Step 1 — Cost rollup (always)

```bash
python3 scripts/analyze-sessions/cost.py --since 30d --by project --limit 10
python3 scripts/analyze-sessions/cost.py --since 30d --by day
```

Look for: a project or model dominating spend, a day spike, a high-error session.
Record the numbers verbatim — they are the evidence, not a vibe.

### Step 2 — Struggle detection

```bash
python3 scripts/analyze-sessions/cost.py --since 30d --errors-only --by session --limit 10
```

Sessions with many errors are where the agent struggled. For the top few, render them
to see *why*:

```bash
python3 scripts/analyze-sessions/show_session.py --session <id> --max-thinking -1
```

### Step 3 — Prompt-pattern mining

```bash
python3 scripts/analyze-sessions/prompts.py --since 30d --max-chars 1500
```

Read the dump and group by recurring themes: a correction you repeat across projects,
a setup question you always ask, a complaint that keeps returning. These are the
highest-value captures — a repeated correction is a missing instruction; a recurring
complaint is an unresolved problem.

### Step 4 — Capture (the loop closes)

Route findings into KBS exactly like any other capture. **Capture; do not ingest.**

| Finding | Where it goes | Pattern |
|---|---|---|
| A correction or instruction you keep re-typing | `INBOX` → proposal to sharpen `agents.md`/system rule | Solution / Idea |
| A recurring complaint or repeated struggle | `INBOX §Open Questions` | Problem / Question |
| A recurring error pattern in sessions | `INBOX` → contradiction / Learning Trigger | Confusion |
| A cost concern (runaway project/model) | `ACTIONS.md` proposal at close | Action |
| A topic your sessions keep circling | `INBOX` → wiki stub on ingest | Question |
| Something that now works smoothly (was a struggle) | `INBOX` → `SUCCESSES.md` stub | Solution (+ evidence) |

Rules for capture:

- **Attribute and timestamp** every captured entry (LLM + date), confidence LOW (rule 8).
- **Proposals only.** A repeated correction is a *suggestion* to change a system rule,
  never a silent edit to `agents.md`/`SYSTEM.md` (rule 2). Write it to
  `outputs/pending-[date].md`.
- **Never write wiki claims directly.** Findings travel the INBOX pipeline.
- **Never retain raw transcripts in the wiki.** Quote only the specific prompt/error that
  evidences a finding; the session store is the source, KBS holds the distilled capture.

---

## What This Is Not

- **Not surveillance of the owner.** It reports cost, patterns, and agent struggles —
  never human qualities (rule 5).
- **Not a standing job.** Passive: it runs only on the explicit prompt, like every other
  operation (rule 1).
- **Not ingestion.** Nothing here creates a wiki claim; it produces captures.

---

## Report Format

```
SESSION ANALYSIS — YYYY-MM-DD
KB: [name]
Window: [since] → [until]

### Cost
- Total: $[x] over [n] sessions
- By project (top): [project $x] ...
- By model (top): [model $x] ...
- Notable spike: [date / session]

### Struggles (error-heavy sessions)
- [session id] — [n] errors — [what went wrong]

### Prompt Patterns
- [theme] — seen [n]x — [example prompt]

### Captured Back to KBS
- Open questions: [n] — [list]
- Confusions / recurring errors: [n] — [list]
- Proposals (system-rule sharpening): [n] — outputs/pending-[date].md
- Solution stubs (now-smooth workflows): [n] — [list]

### Actions Proposed
- [action] due [date] → ACTIONS.md at close
```

---

## Notes

- The scripts are KBS system-owned (`scripts/analyze-sessions/`) and synced to every
  instance. They read the **harness's** session store; a different harness needs its own
  exporter (see architecture.md → *The Harness Layer*).
- Analysis output is **read-only evidence**. Nothing is captured automatically — the
  owner runs the operation and confirms captures, consistent with rule 1.
