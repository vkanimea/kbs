# KBS Input & Output Guide — V0.113

Everything a user inputs. Everything the system outputs. How styles work. How patterns work. How they connect. What is acceptable. What is not. How to add your own input style.

---

## The Fundamental Rule

```
You write in INBOX.md (or 3 specialist files for urgent items).
The system detects your style, extracts patterns, and routes everything.
You never write directly into the wiki.
```

---

## The 4 Input Files (Front Desk)

| File | What Goes Here |
|------|---------------|
| `INBOX.md` | **Everything** — any style, any format, any content |
| `CHAT_INBOX.md` | AI conversations only |
| `FAILURES.md` | Urgent mid-session failures — cannot wait until close |
| `SUCCESSES.md` | Urgent mid-session wins — cannot wait until close |

INBOX.md is the default. When in doubt, write there.

---

## The 5 Built-In Input Styles

The system auto-detects your style before doing anything else. No prefix needed. Just write.

---

### Style 1 — Structured

**What it looks like:** deliberate use of pattern labels.

```markdown
### 2026-06-11 09:00
Problem: SharePoint search returns irrelevant results after migration.
Observation: Users opening 3–4 results before finding right document.
Hypothesis: Metadata not mapped correctly during migration.
Solution: Forced full crawl after verifying metadata mapping.
Conditions: Metadata must be mapped before crawl runs.
Limitations: Does not fix gaps in source metadata.
Evidence: Relevance up 40%. Click depth 4 → 1.2.
Question: What other ranking signals can be tuned post-migration?
```

**Detected by:** pattern labels at start of lines (Problem: / Solution: / etc.)
**Processing:** labels read directly — no inference needed.
**Output:** richest possible — 5+ wiki topics, Causes/Leads To/Depends On links, SUCCESSES.md entry.
**Session close:** no expansion needed — routes directly.
**Frontmatter override:** `---\nstyle: structured\n---` bypasses detection.

---

### Style 2 — Narrative

**What it looks like:** plain sentences, natural writing, no labels.

```markdown
### 2026-06-11 14:30
The crawl fixed the relevance issue after we mapped metadata first.
40% improvement. Need to check what other signals affect ranking.
```

**Detected by:** complete sentences with verbs, no pattern labels.
**Processing:** LLM infers which patterns are present from sentence meaning.
**Output:** good — 2–3 wiki topics, Causes or Related links depending on inference confidence.
**Session close:** may ask one enrichment question per ambiguous inference.

---

### Style 3 — Rapid

**What it looks like:** a fragment, keyword, or shorthand captured under time pressure.

```markdown
### 2026-06-11 16:45
metadata before crawl — not after
```

**Detected by:** fewer than 2 complete sentences, no verb or implied verb, keywords only.
**Processing:** HELD — not rated, not rejected. Moved to `INBOX §Held`.
**Output:** none yet — created after session close expansion.
**Session close:** LLM asks one targeted question: *"You captured: 'metadata before crawl — not after' — what was the problem, solution, or insight? Add any context."* Owner expands → treated as Narrative → full processing.

**Rapid entries are never rated Poor. Held ≠ Poor. Held = incomplete, expanded at close.**

---

### Style 4 — Document

**What it looks like:** a full paste of raw material — meeting notes, email threads, articles, feedback.

```markdown
### 2026-06-11 17:00
Meeting — Search Project Review
Attendees: Sarah, James, Dev team
Problem: Users still clicking too many results after migration
Decision: Run monthly crawl audit going forward
Action: James to document crawl schedule config by Friday
Open question: Do managed metadata columns affect ranking weight?
Next steps: Pilot test with 10 users after next crawl cycle
```

**Detected by:** 200+ words, or section headers, or meeting/email structure, or multiple clearly distinct topics.
**Processing:** split into logical chunks at paragraph/section boundaries. Each chunk processed independently through the full pipeline — rated separately, linked separately.
**Output:** multiple wiki topics, multiple links — including links between chunks.
**Session close:** confirm batch: *"Extracted 4 entries from your meeting notes: [list]. Confirm all, or tell me which to keep or discard."*

---

### Style 5 — Voice

**What it looks like:** a transcribed voice note with filler words and false starts.

```markdown
### 2026-06-11 17:30
So um, the crawl, the crawl fixed it right, like after we — after we
mapped the metadata first. Um the relevance went up like 40% I think.
Need to check what other signals, you know, what other ranking signals
we can tune after the migration.
```

**Detected by:** filler words (um, uh, like, so, you know), false starts, phrase repetition.
**Processing:** strip filler and noise first — keep all substantive content, numbers, names, technical terms. Treat cleaned output as Narrative.
**Output:** same as Narrative after cleaning.
**Session close:** *"Cleaned your voice note. Extracted: [summary]. Does this capture what you meant?"*

---

## Custom Styles — The Extension Point

The 5 built-in styles cover the most common input formats. But any recurring input type not covered by them can be registered as a custom style in `SYSTEM.md §Custom Styles`.

**Once registered, custom styles are auto-detected and processed automatically — no prefix needed.**

### What a Custom Style Definition Contains

```yaml
name: [Style name]
description: [What kind of input this is]
detection_signals:
  - [Signal 1 — specific enough to distinguish from built-in styles]
  - [Signal 2]
processing_rules:
  - [What to do with raw input before extracting patterns]
  - [What to keep, strip, or split]
quality_floor: [Excellent / Good / Variable / Not rated until processed]
link_richness: [High / Medium / Low / Same as Narrative]
fallback: [Which built-in style to use if processing fails]
session_close: [What confirmation or expansion happens at close]
```

### Example Custom Styles

**Email Thread:**
```
Detected by: From: / To: / Subject: headers
Processing: extract sender, recipients, decisions, action items, questions
Fallback: Document
```

**Code Comment:**
```
Detected by: // or # prefix, line <80 chars, no complete sentence
Processing: extract intent, rationale, linked component
Fallback: Rapid (if too terse) or Narrative (if readable)
```

**SOAP Note (clinical):**
```
Detected by: Subjective: / Objective: / Assessment: / Plan: labels
Processing: read labels directly (same as Structured)
Fallback: Structured
```

**Slack Export:**
```
Detected by: [username] [HH:MM] pattern, @mentions, emoji reactions
Processing: extract decisions, blockers, action items; ignore reactions and social messages
Fallback: Document
```

**YouTube Transcript:**
```
Detected by: Source: youtube.com or youtu.be URL; raw/ file with "-transcript" suffix
Processing: split at timestamps; extract claims, advice, definitions; preserve timestamps in sources
Fallback: Document
Helper: scripts/youtube-ingest.sh (downloads audio + transcribes + creates INBOX entry)
```

**The rule for adding a custom style:** it must define detection signals specific enough that the LLM will not confuse it with one of the 5 built-in styles, and processing rules that produce clean output ready for pattern extraction. Any input format can be a valid custom style if it follows this definition.

---

## The 8 Input Patterns

Patterns are extracted in Step 3 of the pipeline — after style processing. They are the same for all styles.

| Pattern | Shape | What It Generates |
|---------|-------|------------------|
| **Problem** | `Problem: [issue + context]` | Wiki topic + open question flag |
| **Solution** | `Solution: [what] + Conditions + Limitations + Evidence` | Wiki topic + SUCCESSES.md entry + confidence upgrade |
| **Question** | `Question: [specific, answerable]` | Wiki stub + gap flag |
| **Observation→Hypothesis** | `Observation: X → Hypothesis: Y` | Wiki topic (MEDIUM confidence claim) |
| **Idea** | `Idea: [cross-domain connection]` | Typed link between two topics |
| **Input** | `PDF/MD/TXT/CSV: [file] — [instruction]` | Wiki topics from document |
| **Confusion** | `Confusion: [contradicts expectations]` | Contradiction flag + learning trigger |
| **Combination** | Multiple patterns together | All of the above |

---

## How Style, Pattern, and Link Connect

This is the core relationship — currently undefined in previous versions:

```
STYLE (how you wrote it)
        ↓ determines how the LLM reads and prepares the input
PATTERN (what was extracted)
        ↓ determines what wiki topics are created
LINK TYPE (what relationship is built)
        ↓ determines what questions the system can answer later
```

### The Link-Richness Curve

| Patterns Extracted | Strongest Link Possible | Questions Answerable Later |
|-------------------|------------------------|---------------------------|
| Problem + Solution + Conditions + Evidence | Causes | "What caused X?" "How was X solved?" "Under what conditions?" |
| Problem + Observation + Hypothesis | Leads To (MEDIUM) | "What does X lead to?" |
| Solution only | Causes (what it resolves) | "What fixed X?" |
| Question only | Related | "What relates to X?" |
| Idea | Related (cross-domain) | "What connects X and Y?" |
| Rapid (before expansion) | None | None until expanded |
| Document batch | Multiple types | Depends on chunks |

---

## The Quality Rating (Step 4 — After Extraction)

Quality is rated on **extracted content** — not on the raw input style.

| Rating | Criteria | Action |
|--------|----------|--------|
| Excellent | 2+ patterns; specific; linkable to 2+ topics; contextual | Process fully; generate follow-up questions |
| Good | 1 pattern; mostly clear | Process; flag for enrichment |
| Poor | Genuinely vague after best-effort extraction | Reject with rewrite suggestion using entry patterns |
| Held | Rapid style — not yet expanded | Move to §Held; expand at session close; rate then |

**Implicit failure detection:** During routing, if a Problem pattern matches a wiki topic upgraded to HIGH within the last 90 days, flag as a recurring problem rather than creating a duplicate topic.

---

## What the System Outputs (Never Written by the User)

### From Session Close

| Output | Where |
|--------|-------|
| Wiki topic pages | `wiki/topics/` |
| Typed links between topics | Inside wiki pages |
| Success entries | `SUCCESSES.md` |
| Failure entries | `FAILURES.md` |
| Decision proposals | In chat (owner pastes) |
| Action entries | `ACTIONS.md` |
| Achievement entries | `CAREER.md` |
| Open questions | `INBOX §Open Questions` |
| Expanded Rapid entries | Fully processed after expansion |
| Confirmed Document batches | Multiple wiki topics and links |
| Confirmed Voice extractions | Processed as Narrative |
| Session close report | In chat |
| Log entry | `log.md` |

### From Ingestion

| Output | Where |
|--------|-------|
| Wiki topics | `wiki/topics/` |
| Held entries | `INBOX §Held` |
| Quality rejections with rewrites | `outputs/pending-quality-review.md` |
| Snapshots | `wiki/snapshots/` |
| Log entry | `log.md` |

---

## The Complete Input → Output → Link Map

```
YOU WRITE                 STYLE DETECTED    PATTERNS EXTRACTED    LINKS CREATED
──────────────────────────────────────────────────────────────────────────────
Labelled entry        →   Structured    →   All patterns read   →  Causes/Leads To/
                                            directly                Depends On

Plain sentences       →   Narrative     →   Patterns inferred   →  Causes or Related
                                            from meaning            (by confidence)

Fragment/keyword      →   Rapid         →   HELD until close    →  None until
                                                                    expanded

Full document paste   →   Document      →   Multiple patterns   →  Multiple links
                                            per chunk              between chunks

Voice transcript      →   Voice         →   Cleaned → same as  →  Same as Narrative
                                            Narrative

Custom format         →   Custom        →   Per definition      →  Per definition
```

---

## One-Page Summary

```
5 BUILT-IN STYLES  Structured · Narrative · Rapid · Document · Voice
                   Auto-detected — no prefix needed
                   Frontmatter override: ---\nstyle: [name]\n---

CUSTOM STYLES      Define in SYSTEM.md §Custom Styles
                   Any format valid if it follows the definition template
                   Detected automatically once registered
                   Fully worked Email Thread example included

8 PATTERNS         Problem · Solution · Question · Observation→Hypothesis
                   Idea · Input · Confusion · Combination

4 QUALITY RATINGS  Excellent · Good · Poor · Held
                   Rapid = Held (never Poor)
                   Quality rated on extracted content, not raw style
                   Implicit failure detection on recurring problems

LINK TYPES         Causes · Leads To · Depends On · CONSTRAINS · Related
                   Richness depends on pattern completeness

4 ENTRY POINTS     INBOX.md (everything) · CHAT_INBOX.md · FAILURES.md · SUCCESSES.md

3 COMMANDS         Ingest · Close session · Query
                   (weekly · every session · daily)

SUPPORT SCRIPTS    status.sh · auto-close.sh · due-actions.sh · topic-index.sh
                   health-check.sh · chat-adapter.sh · chat-api-adapter.py
```
