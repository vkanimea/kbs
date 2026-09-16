# PROMPTS.md — Canonical Prompt Reference (V0.115)

Single source of truth for all prompts. Replace `[KB]` with your knowledge base name (default `main`).

---

## ⭐ The Non-Negotiable

```
Follow agents.md. Close session for [KB]
```
Run after every meaningful work session. This routes everything — successes, failures, decisions, actions, achievements, open questions — automatically.

---

## Daily

| Action | Prompt |
|--------|--------|
| Query | `Follow agents.md. Query [KB]: [your question]` |
| Journal | `Journal: [your reflective writing — any topic, any length]` |
| Compound | `Yes, compound the answer from outputs/[filename] to INBOX.md` |

---

## Weekly

| Action | Prompt |
|--------|--------|
| Ingest | `Follow agents.md. Ingest [KB]` |
| Chat ingest | `Follow agents.md. Process CHAT_INBOX.md` |
| Failures | `Follow agents.md. Process FAILURES.md` |
| Successes | `Follow agents.md. Process SUCCESSES.md` |
| Actions | `Follow agents.md. Process ACTIONS.md` |
| Check pending | `Follow agents.md. Show me all pending approvals and quality reviews. Do not change anything.` |

---

## Monthly

| Action | Prompt |
|--------|--------|
| Health check | `Follow agents.md and SYSTEM.md. Run health check on [KB]` |
| Approve | `Follow agents.md. Approve items [list] from outputs/pending-[date].md. Reject [list] because [reason]. Apply approved changes.` |
| Career summary | `Follow agents.md. Show me career portfolio summary: top skills, recent achievements, gaps.` |
| Unresolved failures | `Follow agents.md. Show me unresolved failures from FAILURES.md older than 30 days.` |
| Unvalidated successes | `Follow agents.md. Show me successes marked Repeatable: Unknown older than 30 days.` |
| Overdue actions | `Follow agents.md. Show me open actions from ACTIONS.md older than 14 days.` |

---

## On Demand

| Action | Prompt |
|--------|--------|
| Status | `Follow agents.md. Status report on [KB]` |
| Journal review | `Follow agents.md. Review my journal entries from the last 30 days. Detect any patterns.` |
| Text graph (20+ topics) | `Follow agents.md. Show me text graph of [KB]. List hubs, orphans, and clusters.` |
| Missing links | `Follow agents.md. Find missing links in [KB]. Suggest 5 new typed links. Write to pending.` |
| Hubs & bridges (50+) | `Follow agents.md. Show me hubs and bridges in [KB].` |
| Solutions summary | `Follow agents.md. Show me all solutions in SUCCESSES.md with their conditions.` |
| Problem→Solution map | `Follow agents.md. Show me which problems have documented solutions and which do not.` |

---

## Initial Setup (Run Once)

```
I have set up my knowledge base. Read agents.md and SYSTEM.md.
Confirm: you are the librarian — you organize, link, and expand,
but never delete or judge without approval. The system is passive
at Level 0. Links are explicit only. You cannot detect human
qualities. Before any operation, read its reference file as listed
in agents.md. There are 8 input patterns — including Solution — and
3 modes. INBOX.md is the default entry point for everything.
```

---

## Batch Approval

```
Approve all
Approve items 1,3,5. Reject 2 and 4 because [reason]
Approve all except #4 because [reason]
```
