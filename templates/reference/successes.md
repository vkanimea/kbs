# Reference: Success Processing (V0.113)

Loaded when the owner runs: `Follow agents.md. Process SUCCESSES.md`

---

## Procedure (Per Unprocessed Entry)

1. Extract the validated claim or confirmed prediction
2. Find the corresponding wiki topic(s)
3. Propose a confidence upgrade:

| Original | After Success | Action |
|----------|---------------|--------|
| LOW | MEDIUM | Corroborated by one real outcome — add supporting evidence |
| MEDIUM | HIGH | Confirmed by data or repeated outcomes — upgrade claim |
| HIGH | HIGH | Reinforces existing claim — add evidence reference |

4. Draft the supporting evidence text for the wiki topic
5. Check Conditions and Limitations — add these to the wiki claim so future readers know when it applies
6. Link the topic back to the SUCCESSES.md entry as evidence
7. Write all proposals to `outputs/pending-[date].md` — apply only after approval (Level 0–1)
8. After approval: apply, mark entry as processed, append to `log.md`

**Never auto-mark `Repeatable: Yes`** — only the owner judges repeatability after seeing the outcome in context.

---

## Conditions and Limitations Are Mandatory

A success without conditions is a dangerous wiki claim. The wiki topic must include:
- When this works (conditions)
- When this does NOT work (limitations)

If the SUCCESSES.md entry is missing these, ask the owner before processing.

---

## Pattern Detection

While processing, flag in the report:
- Successes that contradict existing FAILURES.md entries — these need owner review
- Claims upgraded to HIGH that were previously downgraded — note the reversal
- Repeated successes across different contexts → strengthen to HIGH with broader conditions

---

## Report Format

```
SUCCESS PROCESSING REPORT — YYYY-MM-DD
Successes processed: [n]
Confidence upgrades proposed: [n] — [topic: LOW→MEDIUM, ...]
Evidence added: [n]
Conditions/Limitations noted: [n]
Contradictions with FAILURES.md: [n] — [list]
Awaiting approval: outputs/pending-[date].md
```
