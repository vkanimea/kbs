# FAILURES.md — Learning From What Didn't Work (V11.3)

A failure not documented is a lesson lost. The mirror of SUCCESSES.md — together they drive confidence up and down based on evidence, not opinion. Never delete entries.

**Auto-populated by:** session close. Also write here directly for urgent mid-session captures.
**Process with:** `Follow agents.md. Process FAILURES.md`

---

## Entry Template

```markdown
## YYYY-MM-DD | [Failure title]
**What failed:** [what was wrong]
**Expected vs actual:** [prediction] vs [reality]
**Root cause:** [why — be specific. What assumption was wrong?]
**Evidence:** [logs, data, observations, dates]
**Wiki impact:** [[topic]] needs [caveat / contradiction / downgrade]
**Confidence change:** HIGH/MEDIUM/LOW → HIGH/MEDIUM/LOW
**Lesson:** [one sentence — what to do differently]
**Resolved:** No
```

**Quick capture** (flesh out at session close):
```markdown
## YYYY-MM-DD | [title]
**What failed:**
**Root cause:**
**Lesson:**
**Resolved:** No
```

<!-- EXAMPLE — delete this block after reading -->
```markdown
## 20XX-01-01 | SharePoint crawl ran before metadata mapping was complete
**What failed:** Ran the post-migration crawl before verifying metadata mapping.
**Expected vs actual:** Expected search relevance to improve — it did not change.
**Root cause:** Assumed the crawl would re-index correctly regardless of metadata state. Wrong — the crawl indexes whatever is there; if metadata is unmapped, the index reflects that.
**Evidence:** Search relevance scores unchanged after crawl. Metadata audit showed 60% of managed properties unmapped.
**Wiki impact:** [[crawl-strategy]] needs caveat: "Crawl must follow completed metadata mapping, not precede it."
**Confidence change:** HIGH → MEDIUM for "post-migration crawl restores search relevance"
**Lesson:** Always audit metadata mapping completion before running post-migration crawl.
**Resolved:** No
```
<!-- END EXAMPLE -->

---

## Confidence Downgrade Rules

| Original | After Failure | Action |
|----------|---------------|--------|
| HIGH | MEDIUM | Add caveat, mark as conditional |
| HIGH | LOW | Strong contradiction, needs new evidence |
| MEDIUM | LOW | Weak claim, consider archiving |
| LOW | LOW | Already weak — flag for review |

---

## Relationship to SUCCESSES.md

A resolved failure often has a corresponding success — the solution that eventually worked. When marking `Resolved: Yes`, link to the SUCCESSES.md entry that resolved it:

```markdown
**Resolved:** Yes — 20XX-01-08
**Resolution:** See SUCCESSES.md: "Full crawl restored relevance after metadata mapping"
```

---

## Active Failures (Unresolved)

*Health check flags anything here older than 30 days.*

---

## Resolved Failures

*Move here when owner marks resolved. The owner — never the LLM — marks resolution.*
