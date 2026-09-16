# SUCCESSES.md — Learning From What Worked (V0.115)

The mirror of FAILURES.md. Captures validated wins, confirmed predictions, and solutions that worked — with the conditions under which they work and the conditions under which they do not. Without this file, the system can only downgrade confidence when things fail. It can never upgrade confidence when things are validated.

**Auto-populated by:** session close when a Solution pattern or validated outcome is detected in INBOX.md.
**Process with:** `Follow agents.md. Process SUCCESSES.md`
**Never delete entries.**

---

## Entry Template

```markdown
## YYYY-MM-DD | [Success title]
**What worked:** [what was predicted or tried]
**Expected vs actual:** [prediction] vs [result]
**Conditions:** [under what circumstances — be specific]
**Limitations:** [when this does NOT work]
**Evidence:** [data, observations, dates]
**Wiki impact:** [[topic]] confidence upgrade or new supporting claim
**Confidence change:** LOW/MEDIUM → MEDIUM/HIGH
**Repeatable:** Yes / Conditional / Unknown
**Lesson:** [one sentence — when to apply this again]
```

**Quick capture** (flesh out at session close):
```markdown
## YYYY-MM-DD | [title]
**What worked:**
**Conditions:**
**Limitations:**
**Lesson:**
**Repeatable:** Yes / Conditional / Unknown
```

<!-- EXAMPLE — delete this block after reading -->
```markdown
## 20XX-01-01 | Full crawl restored SharePoint search relevance after migration
**What worked:** Forcing a full content store crawl after verifying metadata mapping.
**Expected vs actual:** Expected 40% relevance improvement — measured exactly 40%.
**Conditions:** Metadata must be correctly mapped to managed properties before crawl runs. Content store must be accessible to the crawl account.
**Limitations:** Does not repair gaps in the source metadata itself. Only re-indexes what is already mapped correctly.
**Evidence:** Search relevance scores improved 40%. User average click depth dropped from 4.0 to 1.2 over one week post-crawl.
**Wiki impact:** [[crawl-strategy]] new HIGH confidence claim. [[metadata-mapping]] Depends On relationship confirmed.
**Confidence change:** MEDIUM → HIGH for "full crawl restores relevance after metadata mapping"
**Repeatable:** Conditional
**Lesson:** Always verify metadata mapping before running post-migration crawl — the crawl indexes what is there, it does not fix what is missing.
```
<!-- END EXAMPLE -->

---

## Confidence Upgrade Rules

When processing a success entry, the LLM proposes:

| Original | After Success | Action |
|----------|---------------|--------|
| LOW | MEDIUM | Corroborated by one real outcome |
| MEDIUM | HIGH | Confirmed by data or repeated outcomes |
| HIGH | HIGH | Reinforces existing claim — add supporting evidence |

Upgrades require approval at Level 0–1. The LLM never auto-applies them.

---

## Active Successes (Conditions Not Yet Fully Validated)

*Successes marked `Repeatable: Conditional` or `Unknown` live here until conditions are confirmed.*

---

## Validated Successes

*Successes marked `Repeatable: Yes` with confirmed conditions.*
