# DECISIONS.md — Judgement Log (V0.113)

**The LLM never writes here. Human only.** Session close proposes decision text in the close report — you read it, edit if needed, and paste what you agree with. This is the most human file in the system.

This file captures *why you believe what you believe* — trade-offs, rejections, and the reasoning behind choices that were not obvious. Routine choices do not belong here. Decisions belong here when you chose between real alternatives and the reasoning matters for the future.

**The difference from ACTIONS.md:** a decision is a judgement about what to believe or how to approach something. An action is a commitment to do something.

---

## Entry Template

```markdown
## YYYY-MM-DD: [Decision title]
**Context:** [what was happening]
**Alternatives considered:**
- [Option A] — why not chosen
- [Option B] — why not chosen
**Decision:** [what you chose]
**Reason:** [why, over the alternatives]
**Source:** [evidence or experience]
**Review date:** YYYY-MM-DD
```

<!-- EXAMPLE — delete this block after reading -->
```markdown
## 20XX-01-01: Always audit metadata before post-migration crawl
**Context:** Ran post-migration crawl before metadata audit — relevance did not improve. Wasted 2 days diagnosing why.
**Alternatives considered:**
- Run crawl first, then audit — faster but risky as this failure showed
- Run audit and crawl simultaneously — still risky, same root cause
**Decision:** Audit metadata mapping completion first, then crawl. Crawl is the last step, not the first.
**Reason:** Crawl indexes what is there. If metadata is unmapped, the crawl locks in the problem. Auditing first costs 2 hours and saves days of diagnosis.
**Source:** FAILURES.md: "SharePoint crawl ran before metadata mapping was complete"
**Review date:** 20XX-07-01
```
<!-- END EXAMPLE -->

---

## Decisions

*Newest first. Paste proposed text from session close reports here.*
