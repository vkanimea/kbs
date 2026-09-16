# KBS User Guide — V0.115

> **A session without a close is a session without learning.**

Exact prompt wording for everything: **PROMPTS.md** (single source).
Full pattern reference and root ideas: **docs/input-output-guide.md**.

---

## First-Time Setup

1. Install (INSTALL.md) — grant your LLM client access to `~/kbs`
2. Optionally copy the **starter KB** to see a working example: `cp -r ~/kbs/examples/starter-kb/wiki/topics/* ~/kbs/kb/main/wiki/topics/`
3. Run the **Initial Setup prompt** from PROMPTS.md
4. Add one entry to INBOX.md using any pattern
5. Run your first close: `Follow agents.md. Close session for main`
6. Set calendar reminders: daily 17:00 auto-close · Monday 09:00 weekly + due-actions · 1st 10:00 health check

---

## What You Write, Where

| You have... | Write in... |
|-------------|-------------|
| A question, idea, problem, observation | `INBOX.md` |
| A solution that worked | `INBOX.md` (Solution: pattern) or `SUCCESSES.md` directly if urgent |
| An AI conversation | `CHAT_INBOX.md` (or pipe through chat-adapter.sh) |
| A mistake or wrong prediction | `INBOX.md` or `FAILURES.md` directly if urgent |
| A document to process | Drop in `raw/` or `raw-assets/pdfs/` + reference in `INBOX.md` |

**INBOX.md is the default.** Session close sorts everything else automatically.

---

## Daily (≈5 min)

**Morning:** one query — `Follow agents.md. Query main: [question]`

**Throughout the day:** capture to INBOX.md or journal. Four modes — use whichever fits the moment:

```markdown
# Mode 1 — Structured (2 min, best output)
Problem: [issue]
Solution: [fix] · Conditions: [when] · Limitations: [when not] · Evidence: [proof]
Question: [what next]

# Mode 2 — Natural (30 sec, good output)
The fix worked — relevance up 40% after mapping metadata first.
Need to check what other signals affect ranking.

# Mode 3 — Minimal (5 sec, clarified at close)
metadata before crawl — not after

# Mode 4 — Journal (2 min, reflective)
Journal: I'm struggling with creative block on video titles again.
I know how to write clickbait but I hate it. I make literal titles
and get fewer views. This keeps coming up.
```

**Optional frontmatter override** (for edge cases where auto-detection struggles):
```markdown
---
style: rapid
---
metadata before crawl — not after
```

**End of session:**
```
Follow agents.md. Close session for main
```
The LLM asks 6 questions: new concepts? problems? solutions? failures? decisions? actions? Everything routes automatically. You paste any decisions you agree with into DECISIONS.md.

---

## Weekly (≈30 min)

```
Follow agents.md. Ingest main
Follow agents.md. Process CHAT_INBOX.md
Follow agents.md. Process FAILURES.md
Follow agents.md. Process SUCCESSES.md
Follow agents.md. Process ACTIONS.md
Follow agents.md. Show me all pending approvals. Do not change anything.
```

Status anytime: `~/kbs/scripts/status.sh`
Due actions: `~/kbs/scripts/due-actions.sh`
Topic search: `~/kbs/scripts/topic-index.sh "search term"`
Semantic search (RAG): `~/kbs/scripts/rag-query.sh "phrase it any way"`

---

## Monthly (≈60 min)

```
Follow agents.md and SYSTEM.md. Run health check on main
```

Then review and approve proposals, career summary, unresolved failures, unvalidated successes, and overdue actions. All prompts in PROMPTS.md.

---

## The Solution Pattern — Most Commonly Missed

Every problem you solve is worth documenting with conditions. Without conditions a solution becomes an overconfident wiki claim that misleads you the next time.

```markdown
Solution: [what was done]
Solves: [the problem]
Conditions: [when this works — be specific]
Limitations: [when it does NOT work]
Evidence: [how you know]
```

At session close the LLM will create a SUCCESSES.md entry and propose a confidence upgrade on the relevant wiki topic.

---

## The Problem→Solution Loop

This is the core learning cycle:

```
Problem captured in INBOX
        ↓
Wiki topic created (LOW or MEDIUM confidence)
        ↓
Solution found → captured in INBOX with conditions
        ↓
SUCCESSES.md entry created
        ↓
Wiki claim upgraded to HIGH (with conditions)
        ↓
Next time you face same problem:
Query main → system finds HIGH confidence solution with conditions
```

Without documenting solutions, the system accumulates problems but never resolves them in the wiki. The health check tracks the Problem:Solution ratio and flags when it drifts too far apart.

---

## Handling Failures

Capture urgently:
```markdown
## 2026-06-11 | [title]
**What failed:**
**Root cause:**
**Lesson:**
**Resolved:** No
```

Or just write naturally in INBOX.md — session close will route it:
```markdown
Tried running the crawl before mapping metadata — made no difference.
Wrong assumption: thought the crawl would fix relevance regardless.
```

When a failure is eventually resolved link it to the success that resolved it.

---

## Queries and Compounding

```
Follow agents.md. Query main: When does a post-migration crawl restore search relevance?
```

The system reads the INDEX, finds `[[crawl-strategy]]`, `[[metadata-mapping]]`, `[[search-relevance]]`, traverses their relationships, and synthesises an answer that includes confidence levels and conditions. It cites which topics it used and saves to outputs/.

Say yes to compounding when the answer is useful — it feeds back into INBOX and makes the wiki smarter than its original sources.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Problems outnumber solutions | Document what worked — even partial wins. Use Solution: pattern. |
| Solutions missing conditions | Health check will flag them. Add conditions before next close. |
| Many orphan topics | Run missing-links review; approve typed link proposals |
| Shallow query answers | More Mode 1 entries; run ingestion after adding structured content |
| Journal feels generic | Prefix with `Journal:` so the LLM reads wiki context before responding |
| No patterns detected | Review journal entries weekly; patterns need ≥3 entries in 30 days |
| CAREER.md empty | Every close must add one entry — small wins count. Health check compiles resume bullets, interview stories, and impact metrics. |
| Actions piling up | Weekly `Process ACTIONS.md`; cancel stale ones honestly |
| Chat insights rejected | Attribute (LLM + date); verify before proposing wiki additions |
