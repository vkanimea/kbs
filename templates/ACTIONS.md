# ACTIONS.md — Commitments & Next Steps (V0.115)

Captures decisions to act — tasks and commitments that come out of sessions. Different from DECISIONS.md (which captures why you chose something) and INBOX.md (which captures questions and observations). An action is a commitment with a due date. When completed, its outcome feeds SUCCESSES.md or FAILURES.md — closing the learning loop.

**Auto-populated by:** session close when a commitment or next step is detected in INBOX.md.
**Review weekly** alongside the pending approvals check.

---

## Entry Template

```markdown
## YYYY-MM-DD | [Action title]
**Decided:** [what you committed to do — specific]
**Why:** [one line reason]
**Due:** YYYY-MM-DD or "next session"
**Done:** No
**Outcome:** [fill when complete — feeds SUCCESSES.md or FAILURES.md]
```

**Quick capture:**
```markdown
## YYYY-MM-DD | [title]
**Decided:**
**Due:** next session
**Done:** No
```

<!-- EXAMPLE — delete this block after reading -->
```markdown
## 20XX-01-01 | Document crawl schedule configuration for SharePoint Online
**Decided:** Write a wiki topic on crawl schedule best practices with the settings that worked post-migration.
**Why:** Same problem will occur on the next migration — need repeatable guidance.
**Due:** 20XX-01-08
**Done:** No
**Outcome:**
```
<!-- END EXAMPLE -->

---

## Completing an Action

When done, update the entry:
```markdown
**Done:** Yes — 20XX-01-07
**Outcome:** Created [[crawl-schedule-configuration]] wiki topic. Added to SUCCESSES.md as a repeatable pattern.
```

Then at next session close the LLM will:
- Mark it complete in the log
- Route the outcome to SUCCESSES.md or FAILURES.md as appropriate
- Link the wiki topic to the action that created it

---

## Open Actions

*`Done: No` entries. Health check flags anything here older than 14 days.*

---

## Completed Actions

*Move entries here when done. The outcome record is permanent.*
