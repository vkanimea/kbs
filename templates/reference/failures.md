# Reference: Failure Processing (V0.114)

Loaded when the owner runs: `Follow agents.md. Process FAILURES.md`

---

## Procedure (Per Unprocessed Failure Entry)

1. Extract the failed claim or prediction
2. Find the corresponding wiki topic(s)
3. Propose a confidence downgrade:

| Original | After Failure | Action |
|----------|---------------|--------|
| HIGH | MEDIUM | Add caveat; mark claim as conditional |
| HIGH | LOW | Strong contradiction — needs new evidence |
| MEDIUM | LOW | Weak claim — propose archiving |
| LOW | LOW | Flag for review |

4. Draft the caveat or contradiction text for the wiki topic
5. Link the topic back to the FAILURES.md entry as evidence
6. Write all proposals to `outputs/pending-[date].md` — apply only after approval (Level 0–1)
7. After approval: apply, mark entry's wiki impact as handled, append to `log.md`

**Never delete failure entries.** They are permanent records.
**Never auto-mark `Resolved: Yes`** — only the owner judges resolution.

---

## Pattern Detection

While processing, flag (in the report, and as INBOX learning triggers):
- Topics with ≥2 confidence downgrades in 90 days → possible systemic issue
- Contradictions that re-emerged after a prior resolution
- Repeated rejections of the same source type
- Entries with `Resolved: No` older than 30 days

---

## Report Format

```
FAILURE PROCESSING REPORT — YYYY-MM-DD
Failures processed: [n]
Confidence downgrades proposed: [n] — [topic: HIGH→MEDIUM, ...]
Caveats drafted: [n]
Patterns detected: [list or none]
Unresolved >30 days: [n] — [list]
Awaiting approval: outputs/pending-[date].md
```
