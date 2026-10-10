# Reference: Failure Processing (V0.116)

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
**Resolution requires evidence.** An entry may only move to §Resolved Failures when the `**Resolution:**`
line cites verifiable evidence that the fix actually worked — a command output, a log line with a
timestamp, a test/report ID, or a SUCCESSES.md link. A fix that was *applied* is not a fix that was
*verified*: "restarted the service", "ran the playbook", or "the change was deployed" are not
evidence on their own and must remain `Resolved: No`. When the owner reports a resolution without
evidence, propose the evidence-gathering step instead of marking it resolved.

---

## Pattern Detection

While processing, flag (in the report, and as INBOX learning triggers):
- Topics with ≥2 confidence downgrades in 90 days → possible systemic issue
- Contradictions that re-emerged after a prior resolution
- Repeated rejections of the same source type
- Entries with `Resolved: No` older than 30 days
- Resolved entries whose `**Resolution:**` line cites no verifiable evidence → flag for re-verification
- Failures whose stated lesson is "verify the outcome" yet recur → the verification step itself is missing

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

---

## Worked Exemplar — copy this shape

Required fields: `What failed`, `Root cause`, `Expected vs actual`, `Lesson`, `Resolved`.
`Evidence` / `Wiki impact` are optional; `Resolution:` appears only once resolved.

```markdown
## 2026-10-04 | CLI reported absence via an error line; stderr filtering turned it into "no backups anywhere"
**What failed:** A backup-verification script reported "no backups found" when the underlying CLI had actually errored; the error text was on stderr and was filtered out, so a failed probe looked like a successful empty result.
**Expected vs actual:** Expected "found nothing" to mean the probe ran and there was nothing to find. Actual: the probe never ran successfully — absence and failure were indistinguishable.
**Root cause:** Treating a non-zero exit as "no results" without distinguishing it from "the check could not run at all."
**Lesson:** A verification tool must fail loudly when it cannot run, not report a clean negative; check exit status before interpreting empty output.
**Resolved:** Yes
**Resolution:** Added an explicit exit-status check and made "could not run" a hard error, distinct from "ran and found none."
```
