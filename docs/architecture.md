# KBS Architecture — V0.114

## Overview

KBS is a governed, evolving knowledge graph: plain markdown transformed into a reasoning system that learns from successes and failures, compounds every session, and auto-maintains a career portfolio. Model-agnostic. Works with any LLM.

---

## Version History

See [CHANGELOG.md](../CHANGELOG.md) for the full version history.

---

## Where the Ideas Come From

### Zettelkasten (Niklas Luhmann, 1950s–1990s)
A German sociologist who wrote 70+ books using 90,000 physical index cards. Each card held one idea, linked to others by reference number. He navigated by following links, never by searching. **Links are more valuable than the notes themselves.**

KBS took: one topic per wiki page; every page links to others; navigation over search.

### Knowledge Graphs (Academic AI, 1970s onward)
Knowledge is not a list of facts but a network of typed relationships. The difference between "A relates to B" and "A causes B" is the difference between a map and a reasoning engine.

KBS took: typed relationships (Causes, Leads To, Depends On, CONSTRAINS, Related) enabling causal queries not just navigation.

### Double-Loop Learning (Chris Argyris, Harvard, 1970s)
Single-loop learning fixes the problem. Double-loop learning asks why the problem existed and changes the underlying assumption.

KBS took: FAILURES.md captures the wrong assumption, not just the wrong outcome. SUCCESSES.md validates the assumption. Both drive wiki confidence movement.

### The Scientific Method
Observation → Hypothesis → Test → Result → Update belief.

KBS took: the Observation→Hypothesis pattern; confidence levels as beliefs updated by evidence; SUCCESSES/FAILURES as test results; Conditions and Limitations as the boundaries of where a hypothesis holds.

### Andrej Karpathy's Second Brain (2023–2024)
The LLM does not store knowledge — it organises and links knowledge you bring to it.

KBS took: raw/ → wiki/ → outputs/ pipeline; LLM as librarian not author; plain markdown; nothing happens automatically.

### Reddit r/PromptEngineering Community (2024)
Extended Karpathy with session close, career portfolio, three-layer memory.

KBS took: session close as the single most important ritual; career portfolio auto-maintenance; every session produces compounding value.

### What KBS Added

| Gap | KBS Solution |
|-----|-------------|
| No failure learning | FAILURES.md + confidence downgrades |
| No success learning | SUCCESSES.md + confidence upgrades |
| No solution pattern | Solution: with Conditions and Limitations |
| No graduated autonomy | Activity Levels 0→3 |
| No quality gate | INBOX rating — Excellent/Good/Poor/Held |
| No action tracking | ACTIONS.md |
| No audit trail | log.md append-only |
| Instruction bloat | Lazy-loaded reference modules |
| Fixed input formats only | Style Registry — 5 built-in + extensible custom |
| Rapid entries penalised | Held state — never Poor, expanded at close |
| No reflective practice | JOURNAL.md — grounded responses, pattern detection |
| No automation | hourly-ingest.sh + auto-close.sh + due-actions.sh |

---

## The Six-Stage Pipeline

```
1 CAPTURE    4 entry points — INBOX.md (default) · CHAT_INBOX.md · FAILURES.md · SUCCESSES.md

2 STORE      raw/ (text) + raw-assets/ (PDFs, images) — immutable originals

3 INGEST     6-step pipeline (see below)
             Pass → Stage 4   |   Fail → pending-quality-review.md   |   Hold → INBOX §Held

4 BUILD      wiki/topics/ — typed knowledge graph with confidence levels

5 QUERY      6-step: INDEX → topics → relationships → synthesise → cite → save → compound?

6 IMPROVE    Session close: expand held, confirm batches, route everything, compound
             → loops back to Stage 1
```

---

## The 6-Step Ingestion Pipeline (V0.114)

This is the core processing architecture. Every INBOX entry passes through all 6 steps.

```
STEP 1 — DETECT STYLE
Read the entry. Match against SYSTEM.md §Style Registry.
Check in order: Structured → Voice → Document → Rapid → Narrative → Custom
Fallback: Narrative if no match.

STEP 2 — APPLY STYLE PROCESSING
Structured:  read labels directly → Step 3
Narrative:   infer patterns from sentence meaning → Step 3
Rapid:       HOLD — move to INBOX §Held — session close expands — re-enters at Step 1
Document:    split into chunks → each chunk re-enters at Step 1 independently
Voice:       strip filler/false-starts/repetition → treat as Narrative → Step 3
Custom:      apply rules from Style Registry → Step 3

STEP 3 — EXTRACT PATTERNS
Identify which of the 8 patterns are present:
Problem / Solution / Question / Observation→Hypothesis
Idea / Input / Confusion / Combination

STEP 4 — RATE QUALITY (of extracted content — never of raw input)
Excellent  → process fully
Good       → process, flag for enrichment
Poor       → reject with rewrite suggestion
Held       → not rated yet (Rapid entries only)

STEP 5 — CREATE LINKS
Type richness depends on patterns extracted (see Link-Richness Curve below)
Always create the strongest typed link the evidence supports

STEP 6 — ROUTE
wiki/topics/ · SUCCESSES.md · FAILURES.md · DECISIONS.md proposal
ACTIONS.md · CAREER.md · INBOX §Open Questions · INBOX §Held
```

---

## The Style Registry — Extensible Input Architecture (V0.114)

The Style Registry (defined in `SYSTEM.md §Style Registry`) is the single source of truth for how every input is processed. It defines 5 built-in styles and an open extension point.

### The 5 Built-In Styles

| Style | Auto-Detected By | Processing | Quality Floor |
|-------|-----------------|------------|---------------|
| **Structured** | Pattern labels (Problem: / Solution: / etc.) | Read labels directly | Excellent or Good |
| **Narrative** | Complete sentences, no labels | Infer patterns from meaning | Good |
| **Rapid** | <2 sentences, fragment, no verb | HOLD — expand at session close | Not rated until expanded |
| **Document** | 200+ words or section headers or multi-topic | Split into chunks, process each | Variable per chunk |
| **Voice** | Filler words, false starts, repetition | Strip noise, treat as Narrative | Good after cleaning |

### Custom Styles — The Extension Point

Any input format not covered by the 5 built-in styles can be registered as a custom style in `SYSTEM.md §Custom Styles`. A custom style is valid if it defines:

1. **Detection signals** specific enough to distinguish it from the 5 built-in styles
2. **Processing rules** that produce clean output suitable for pattern extraction
3. **A fallback** built-in style if processing fails
4. **Session close behaviour** (what confirmation or expansion is needed)

Once registered, custom styles are detected and processed automatically — no prefix required from the user. The LLM checks the Style Registry before processing any entry.

**Examples of custom styles users have added:**
```
Email Thread    From:/To:/Subject: headers → extract decisions, actions, context
Code Comment    // or # prefix, <80 chars → extract intent and rationale
SOAP Note       Subjective:/Objective:/Assessment:/Plan: → clinical knowledge
Slack Export    [username] [timestamp] pattern → extract decisions and blockers
Legal Clause    WHEREAS / PROVIDED THAT → extract obligations and conditions
```

**The principle:** the system adapts to how users naturally produce information. The 5 built-in styles cover the most common cases. The registry covers everything else. Any input style is valid if it follows the same definition format as the 5 built-in styles. There is no closed list.

---

## The Link-Richness Curve

The type of wiki link the system can create depends directly on the completeness of extracted patterns:

```
PATTERNS EXTRACTED                    LINKS POSSIBLE
──────────────────────────────────────────────────────────────────
Problem + Solution + Conditions       Causes (strongest)
+ Evidence                            Depends On
                                      Leads To
                                      → 3+ typed links

Problem + Observation + Hypothesis    Causes (MEDIUM confidence)
                                      Leads To
                                      → 2 typed links

Solution only                         Causes (what it resolves)
                                      → 1 typed link

Observation only                      Leads To (tentative)
                                      → 1 typed link, LOW confidence

Question only                         Related (stub)
                                      → 1 typed link, LOW confidence

Idea (cross-domain)                   Related (potentially high future value)
                                      → 1 typed link

Rapid (held)                          None until expanded

Document (batch)                      Links between chunks
                                      + links to existing wiki topics
                                      → multiple links, variable types

Voice (cleaned)                       Same as Narrative after cleaning
```

The system always creates whatever links the evidence supports. It never upgrades a link type beyond the evidence. More complete input = richer link types = more powerful reasoning.

---

## Activity Levels × Style Processing Matrix

| Level | Rapid | Document | Voice | Custom |
|-------|-------|----------|-------|--------|
| 0 Passive | Held → owner expands at close | Owner confirms batch at close | Owner confirms cleaned extraction | Owner confirms extraction |
| 1 Mid-Active | Held → scheduled expansion | Proposal for batch approval | Proposal for confirmation | Proposal sent |
| 2 Fully Active | Auto-expand per policy | Auto-processes, flags review | Auto-cleans, flags confirm | Auto-processes per definition |
| 3 Autonomous | Auto-expands and routes | Auto-processes | Auto-processes | Auto-processes |

---

## File Responsibilities

| Concern | Lives In | Everyone Else |
|---------|----------|---------------|
| Core rules, 8 patterns, boundaries | `agents.md` | — |
| Style Registry (built-in + custom) | `SYSTEM.md §Style Registry` | agents.md references it |
| Operation procedures | `reference/*.md` | agents.md maps to them |
| Activity levels, scope, metrics | `SYSTEM.md` | links |
| All prompts | `PROMPTS.md` | links |
| Human judgement | `DECISIONS.md` | LLM proposes, owner pastes |
| Input capture | `INBOX.md` (default) + 3 specialist files | — |
| Commitments | `ACTIONS.md` | populated by close |
| Journal | `JOURNAL.md` | populated by journal operations |
| Portfolio | `CAREER.md` | populated by close |
| History | `log.md` | append-only |
| Input/output reference | `docs/input-output-guide.md` | — |

---

## The Mental Model

```
INBOX.md        = front desk (any style, any format)
Style Registry  = the desk's operating procedures (how to handle each type)
raw/            = archive room (originals never touched)
wiki/topics/    = the library (organised, linked, reasoned)
wiki/archive/   = basement (cold topics, summarised stubs)
journal/        = the confessional (reflective entries, pattern detection)
outputs/        = reading room (answers and synthesis)
FAILURES.md     = incident log
SUCCESSES.md    = validation log
DECISIONS.md    = judgement book
ACTIONS.md      = commitment board
CAREER.md       = portfolio
SYSTEM.md       = operations manual + style registry
log.md          = security camera
reference/      = procedure manuals (loaded on demand)
examples/       = exhibition hall (starter KB for learning)
```

---

## Tooling Ecosystem

| Script | Purpose | Schedule |
|--------|---------|----------|
| `status.sh` | Dashboard: topics, pending, failures, last close | On demand |
| `auto-close.sh` | Streak tracking + pending summary + desktop nudge | Daily 17:00 |
| `due-actions.sh` | Overdue action notifications | Weekday mornings |
| `topic-index.sh` | Lightweight grep-based topic search for 100+ KBs | On demand |
| `rag-index.sh` / `rag-query.sh` | Semantic retrieval (Ollama embeddings, stdlib Python) | Rebuilt after hourly-ingest |
| `health-check.sh` | Monthly reminder + pending/failure summary | Monthly 1st |
| `hourly-ingest.sh` | Auto-process raw/ files + move to raw/processed/ + rebuild RAG index | Hourly |
| `youtube-ingest.sh` | Download YouTube audio + transcribe + INBOX entry | On demand |
| `chat-adapter.sh` | Pipe/file capture to CHAT_INBOX.md | On demand |
| `chat-api-adapter.py` | Webhook server for API capture | On demand |

## The Golden Rules

A session without a close is a session without learning.
Problems without solutions are complaints. Solutions without conditions are dangerous.
Failures are data. Successes are data. Document both.
Rapid entries are held, never rejected. Minimal capture beats no capture.
Any input style is valid — if it is defined in the Style Registry.
The 5 built-in styles cover the common cases. The registry covers everything else.
Start passive. Grow active only as trust earns. Never skip a level.
Links turn documents into thinking.
