# SYSTEM.md — Configuration & Meta-Cognition (V11.3)

Single source of truth for: current context, scope, activity levels, policies, metrics targets, style registry, rituals, and learning triggers. Operation procedures live in `reference/`. Prompts live in `PROMPTS.md`.

---

## Current Context (Updated by Session Close)

```markdown
### Role
[Your current role]

### Active Projects
- [Project] — [status]

### Reading Focus
- [Topic]

### Next Session Focus
- [What to work on]

### Last Session
Date: YYYY-MM-DD | Closed: Yes/No
Problems captured: [n] | Solutions captured: [n] | Failures: [n] | Successes: [n]

### Last Updated: YYYY-MM-DD
```

---

## Scope Boundary

Only ingest content that clearly supports: current role, active projects, reading focus, or existing wiki gaps. Out-of-scope sources are rejected, deferred to INBOX, or parked in `raw/` unprocessed.

---

## Activity Levels — The Definition

**Current Level: 0**

| Level | Name | LLM May | Approval Needed | Upgrade Criteria |
|-------|------|---------|-----------------|------------------|
| 0 | Passive | Respond to prompts only | Everything | — (default) |
| 1 | Mid-Active | Scheduled proposals only | Everything (batch OK) | 20+ topics, 30+ days |
| 2 | Fully Active | Execute routine per §Autonomous Policies | Exceptions only | 50+ topics, 90+ days, clean rollback |
| 3 | Autonomous | Watch folders, auto-ingest, auto-health-check | Policy violations only | 100+ topics, 180+ days, expert users |

**Rules:** Start at 0. Never skip a level. Test rollback before each upgrade.

### Level 1 Scheduling (cron)
```cron
0 9 * * 1  ~/kbs/scripts/health-check.sh
0 10 1 * * ~/kbs/scripts/health-check.sh
```

### Autonomous Policies (Level 2+ — Uncomment When Upgrading)
```markdown
<!--
- Auto-add links when confidence = HIGH
- Auto-archive topics: 0 queries in 90 days AND confidence = LOW
- Auto-delete orphaned assets older than 365 days
- Auto-route completed ACTIONS to SUCCESSES/FAILURES
- NEVER auto-resolve contradictions
- NEVER touch #foundational-tagged topics
- NEVER modify DECISIONS.md
-->
```

### Failure Containment (All Levels)
On repeated rollbacks, policy violations, or sequential low-quality outputs:
1. Downgrade level by 1
2. Stop autonomous execution
3. Write `outputs/pending-failure-review-[date].md`
4. Human approval required to re-upgrade

### Activity Levels and Style Processing

| Level | Rapid entries | Document entries | Voice entries | Custom styles |
|-------|--------------|-----------------|---------------|---------------|
| 0 | Held → owner expands at close | Owner confirms batch at close | Owner confirms cleaned extraction | Owner confirms extraction |
| 1 | Held → scheduled close expansion | Proposal sent for batch approval | Proposal sent for confirmation | Proposal sent |
| 2 | Auto-expand per policy | Auto-processes, flags for review | Auto-cleans, flags for confirmation | Auto-processes per definition |
| 3 | Auto-expands and routes | Auto-processes | Auto-processes | Auto-processes |

---

## Style Registry (The Extension Point)

**This is the single source of truth for input style definitions.** The LLM reads this registry before processing any INBOX entry. Styles are detected automatically — no prefix required from the user.

The 5 built-in styles ship with KBS. They serve as the **template** for defining custom styles. Any additional input style can be registered by following the same definition format.

### Optional: Frontmatter Style Override
For edge cases where auto-detection is ambiguous, you may optionally override style detection by adding a YAML frontmatter block at the very top of your entry:

```markdown
---
style: rapid
---
metadata before crawl — not after
```

**Rules:**
- Frontmatter must be the very first content in the entry, before the timestamp heading
- Valid values: `structured`, `narrative`, `rapid`, `document`, `voice`, or any registered custom style name
- The LLM reads the frontmatter first; if present, it skips auto-detection for that entry
- If the frontmatter value does not match a registered style, fall back to auto-detection and log a warning
- Use sparingly — the goal is auto-detection that just works. Frontmatter is for the 5% of edge cases.

### How to Add a Custom Style

Copy any built-in style block below, paste it at the bottom of this registry, and fill in:
- **Name** — what you call it
- **Detection signals** — what the LLM looks for to recognise it automatically
- **Processing rules** — what the LLM does before extracting patterns
- **Fallback** — what to treat it as if processing fails
- **Session close** — what confirmation or expansion happens at close

---

### Built-in Style 1 — Structured

```yaml
name: Structured
description: Deliberate use of explicit pattern labels
detection_signals:
  - Entry contains one or more pattern labels:
    Problem: / Solution: / Question: / Observation: /
    Hypothesis: / Idea: / PDF: / MD: / TXT: / Confusion:
  - Labels appear at the start of a line
processing_rules:
  - Read pattern labels directly — no inference needed
  - Extract all labelled fields as-is
  - Proceed immediately to pattern extraction
quality_floor: Excellent or Good (structured entries rarely Poor)
link_richness: Highest — Causes / Leads To / Depends On possible
fallback: Narrative (if labels present but content too thin)
session_close: No expansion needed — routes directly
```

---

### Built-in Style 2 — Narrative

```yaml
name: Narrative
description: Plain sentences, stream of consciousness, natural writing
detection_signals:
  - Complete sentences with verbs
  - No pattern labels present
  - Reads like a note, paragraph, or journal entry
  - Typically 2–10 sentences
processing_rules:
  - Read full sentences
  - Infer patterns from meaning:
      "it worked" / "fixed" / "solved"        → possible Solution
      "I wonder" / "why does" / "how does"     → possible Question
      "noticed that" / "seems like"            → possible Observation
      "what if" / "connection between"         → possible Idea
      "broke" / "wrong" / "failed"             → possible Failure
      "will do" / "need to" / "next session"   → possible Action
  - Flag inferences for enrichment if ambiguous
quality_floor: Good (may be flagged for enrichment)
link_richness: Medium — Causes or Related depending on inference confidence
fallback: Rapid (if fewer than 2 complete sentences after reading)
session_close: May ask one enrichment question per ambiguous inference
```

---

### Built-in Style 3 — Rapid

```yaml
name: Rapid
description: Fragments, keywords, shorthand — captured under time pressure
detection_signals:
  - Fewer than 2 complete sentences
  - No verb OR verb is implied not stated
  - Keywords only, shorthand, abbreviations
  - Typical length: 3–15 words
processing_rules:
  - Do NOT rate quality yet
  - Do NOT reject
  - Do NOT attempt pattern extraction
  - Mark entry status: HELD
  - Move to INBOX §Held
  - At session close: ask one targeted expansion question per held entry
  - After owner expansion: re-enter pipeline as Narrative
  - Rate quality only after expansion
quality_floor: Not rated until expanded
link_richness: None until expanded — then same as Narrative
fallback: None — always Held, never rejected
session_close: REQUIRED — ask "You captured: [fragment] — what was the
              problem, solution, or insight? Add any context you can."
```

---

### Built-in Style 4 — Document

```yaml
name: Document
description: Full paste of raw material — meeting notes, email threads,
             articles, transcripts, feedback, reports
detection_signals:
  - Entry length 200+ words OR
  - Contains section headers (##, bold headings) OR
  - Contains numbered agenda items OR
  - Contains email headers (From: / To: / Subject:) OR
  - Contains meeting structure (Attendees: / Action Items: / Decisions:) OR
  - Multiple clearly distinct topics in one entry
processing_rules:
  - Split into logical chunks at paragraph or section boundaries
  - Process each chunk as an independent entry
  - Apply style detection to each chunk individually (usually Narrative)
  - Rate each chunk's quality independently
  - Build a batch summary: "Found [n] entries — [list of what was found]"
  - Do not merge chunks — each generates its own wiki topics and links
  - Links between chunks are created just as links between any two topics
quality_floor: Variable per chunk — each chunk rated independently
link_richness: High — multiple entries mean multiple relationships possible,
               including links between chunks themselves
fallback: Narrative (if split produces only one chunk)
session_close: Confirm batch with owner:
               "Extracted [n] entries from document: [list]. Confirm all,
               or tell me which to keep/discard."
```

---

### Built-in Style 5 — Voice

```yaml
name: Voice
description: Transcribed audio — contains filler words, false starts,
             repetition, and transcription noise
detection_signals:
  - Contains transcription artefacts:
    um / uh / like / so / you know / right /
    false starts ("I — I mean" / "the the") /
    exact phrase repetition within 3 sentences /
    trailing incomplete sentences
  - Entry prefixed with VOICE: or TRANSCRIPT: (optional — auto-detected too)
processing_rules:
  - Strip before any other processing:
      remove: um, uh, like, so, you know, right (as filler)
      remove: false starts and restarts
      remove: exact duplicate phrases
      keep: ALL substantive content, numbers, names, technical terms,
             decisions, actions — never remove content words
  - Treat cleaned output as Narrative
  - Flag in processing report: "Cleaned from voice transcript"
  - Show owner the before/after if significant content was removed
quality_floor: Good after cleaning (same as Narrative)
link_richness: Same as Narrative after cleaning
fallback: Narrative (after cleaning)
session_close: Confirm cleaned extraction:
               "Cleaned your voice note. Extracted: [summary].
               Does this capture what you meant?"
```

---

### Custom Styles (Add Yours Here)

To add a custom style, copy this template and fill it in:

```yaml
name: [Style name]
description: [One sentence — what kind of input this is]
detection_signals:
  - [Signal 1 — what the LLM looks for to auto-detect this style]
  - [Signal 2]
  - [Signal 3 — be specific enough that it does not clash with built-in styles]
processing_rules:
  - [Step 1 — what to do with the raw input before extracting patterns]
  - [Step 2]
  - [What to keep, what to strip, how to split if needed]
quality_floor: [Excellent / Good / Variable / Not rated until processed]
link_richness: [High / Medium / Low / Same as Narrative]
fallback: [Which built-in style to treat it as if processing fails]
session_close: [What confirmation or expansion happens at close]
```

### Example Custom Style — Email Thread (Fully Defined)

```yaml
name: Email Thread
description: Email conversations with From/To/Subject headers and quoted replies
detection_signals:
  - Entry contains email headers: From: / To: / Subject: / Date: / CC:
  - Contains quoted reply markers: > at start of lines
  - Contains signature blocks (-- \n or Regards, / Best,)
  - Multiple timestamped exchanges in one entry
processing_rules:
  - Extract metadata: sender, recipients, subject, date
  - Split by message boundary (look for From: or On ... wrote:)
  - For each message: extract decisions, action items, questions, blockers
  - Ignore: signatures, legal disclaimers, formatting artifacts
  - Treat each extracted message as Narrative or Structured depending on content
quality_floor: Variable per message
link_richness: Medium — decisions and action items produce typed links
fallback: Document (if headers are present but parsing fails)
session_close: Confirm batch: "Extracted [n] decisions and [m] action items from email thread. Confirm all, or tell me which to keep or discard."
```

### Example Custom Style — YouTube Transcript

```yaml
name: YouTube Transcript
description: Transcript from a YouTube video, with optional timestamp markers and speaker labels
detection_signals:
  - Entry contains a YouTube URL (youtube.com or youtu.be) in the Source: field
  - Entry references a .txt file in raw/ with "-transcript" in the filename
  - Content includes [HH:MM:SS] timestamp markers or "Speaker:" labels
  - Long text (>500 words) with paragraph breaks and topic shifts
processing_rules:
  - Split into sections at timestamp boundaries or major topic shifts
  - Extract: key claims, actionable advice, definitions, referenced tools/people
  - Preserve timestamps for Claims table Source column: [[topic]] ([00:12:34])
  - Treat each section as Narrative; combine related sections into wiki topics
  - Flag claims that contradict existing wiki topics for contradiction review
quality_floor: Good (transcripts are verbose; extraction quality varies)
link_richness: Medium — claims and definitions produce typed links
fallback: Document (if transcript has clear section headers)
session_close: Confirm batch: "Extracted [n] topics from YouTube transcript. Confirm all, or tell me which to keep or discard."
```

**More examples:**

```
Code Comment    detect: // or # prefix, < 80 chars, no complete sentences
SOAP Note       detect: Subjective:/Objective:/Assessment:/Plan: labels
Slack Export    detect: [username] [timestamp] pattern, @mentions
Legal Clause    detect: WHEREAS / PROVIDED THAT / NOTWITHSTANDING
```

**The rule:** any input style can be registered here as long as it defines detection signals specific enough for the LLM to distinguish it from the 5 built-in styles, and processing rules that produce clean Narrative or Structured output for pattern extraction.

---

## Component Activation Thresholds

| KB Size | Worth Using | Activity Level |
|---------|------------|----------------|
| 1–20 topics | Capture, Ingest, Query, Compound | 0 |
| 20–50 | + Text graph, orphan detection, hubs | 0–1 |
| 50–100 | + Bridges, clusters, contradiction review | 1–2 |
| 100+ | + Trends, Mermaid diagrams, reuse tracking | 2–3 |

---

## Metrics Targets

| Metric | Target | Alert |
|--------|--------|-------|
| Orphan rate | <5% | — |
| Avg links/topic | >2.0 | — |
| HIGH claims with conditions | 100% | Any without = risk |
| Documented failures | ≥1/month | 0 = under-reporting |
| Documented successes | ≥1/month | 0 = under-reporting |
| Success/failure ratio | Neither >3:1 | Imbalance = under-reporting |
| Topics with downgrades | <10% | >20% = systemic |
| Unresolved failures >30d | 0 | >3 = process breakdown |
| Open actions >14d | 0 | >3 = follow-through gap |
| Solutions without conditions | 0 | Any = overconfident claims |
| INBOX Excellent rate | >50% | <30% = capture problem |
| Held entries >7d | 0 | Any = session close not running |
| Solution:Problem ratio | ~1:1 over time | Large gap = unresolved problems |
| Achievements | ≥1/week | 0/month = under-documenting |

---

## Rituals (Owner)

| Frequency | Ritual | Time |
|-----------|--------|------|
| Every session | **Close session** (non-negotiable) | 2 min |
| Daily | One query | 2 min |
| Weekly | Ingest + all processing commands | 30 min |
| Monthly | Health check + batch approve + reviews | 60 min |

Prompts: `PROMPTS.md`.

---

## Learning Triggers

| Trigger | Task Added to INBOX |
|---------|-------------------|
| Contradiction found | "Resolve contradiction between X and Y" |
| LOW confidence persists 30 days | "Review or archive [topic]" |
| Orphan topic | "Find links for [topic]" |
| Held entry >7 days | "Expand held entry from [date]: [fragment]" |
| Unresolved failure >30 days | "Resolve failure from [date]" |
| Success Repeatable:Unknown >30d | "Assess repeatability of success from [date]" |
| Recurring problem pattern | "This problem reappeared despite a prior solution — was the previous solution incomplete?" |
| Topic unqueried >90 days | "Review or archive: [[topic]] — no queries in 90 days" |
| Action overdue | "Complete or cancel action: [title]" |
| Poor INBOX rate >30% | "Review entry patterns — see input-output-guide.md" |
| No solutions this month | "Document what worked this month" |
| Solution without conditions | "Add conditions and limitations to: [title]" |
| Custom style detection failure | "Review style registry — [style] not matching correctly" |
| Frontmatter override mismatch | "Frontmatter style '[name]' not in registry — check spelling or register custom style" |

---

## What the System Cannot Do

It organises text. It cannot detect honesty, courage, love, emotions, or wisdom. It cannot judge what a success or failure means — you must tell it. Activity levels change automation, never detection capability.

---

## Recovery Rituals

| Problem | Replacement Routine |
|---------|--------------------|
| Held entries piling up | Run session close — one Q per entry |
| Custom style misdetecting | Refine detection signals in Style Registry |
| Problems outnumber solutions 3:1 | Actively document what is working |
| Solutions missing conditions | Review SUCCESSES.md; add conditions |
| Skipped closes | Calendar alert — the one non-negotiable |
| Automation feels unsafe | Downgrade level |
