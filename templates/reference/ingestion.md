# Reference: Ingestion (V11.3)

Loaded when the owner runs: `Follow agents.md. Ingest [KB]`

**Before running this pipeline:** read SYSTEM.md §Style Registry. The registry defines detection signals and processing rules for all styles including any custom styles the owner has added.

---

## Acceptable File Formats

| Format | Location |
|--------|----------|
| `.md` `.txt` `.csv` `.json` | `raw/` |
| `.pdf` | `raw-assets/pdfs/` |
| `.png` `.jpg` `.gif` | `raw-assets/images/` |
| `.docx` `.pptx` `.xlsx` | Convert to PDF first → `raw-assets/pdfs/` |
| `.mp3` `.m4a` `.wav` `.mp4` | Transcribe to `.txt` first → `raw/` |
| YouTube | Use `scripts/youtube-ingest.sh` → downloads audio + transcribes + creates INBOX entry |

Files without an INBOX entry referencing them are invisible. Flag orphaned files in the report.

---

## The 6-Step Pipeline

Every INBOX entry passes through all 6 steps in order. Steps 1 and 2 determine how the entry is prepared. Steps 3–6 are the same for all styles.

---

### Step 1 — Detect Style

Read the entry. Classify it using SYSTEM.md §Style Registry detection signals.

Check built-in styles first in this order:
1. **Structured** — pattern labels present?
2. **Voice** — filler words, false starts, repetition?
3. **Document** — 200+ words or section headers or multi-topic?
4. **Rapid** — fragment, <2 sentences, no verb?
5. **Narrative** — complete sentences, no labels? (universal fallback)
6. **Custom** — check any styles defined in SYSTEM.md §Custom Styles

If no style matches clearly: treat as Narrative.

Log detected style in the ingest report.

---

### Step 2 — Apply Style Processing

Apply the processing rules from SYSTEM.md §Style Registry for the detected style:

**Structured:** read pattern labels directly. Proceed to Step 3.

**Narrative:** infer patterns from sentence meaning using signals in the registry. Flag ambiguous inferences for enrichment. Proceed to Step 3.

**Rapid:**
- Mark entry status: **HELD**
- Move to `INBOX.md §Held`
- Do NOT proceed to Steps 3–6 yet
- Session close will ask one expansion question
- After expansion: re-enter at Step 1 as Narrative

**Document:**
- Split into chunks at paragraph or section boundaries
- Each chunk is processed independently through Steps 1–6
- Build batch summary for session close confirmation
- Links between chunks are created in Step 5 just like any other links

**Voice:**
- Strip: um, uh, like, so, you know, right (as fillers); false starts; exact duplicate phrases
- Keep: all substantive content, numbers, names, technical terms, decisions, actions
- Treat cleaned output as Narrative
- Flag: "Cleaned from voice transcript" in report
- Show before/after if >20% of words were removed
- Proceed to Step 3

**Custom style:** apply processing rules as defined in SYSTEM.md §Custom Styles. Produce clean output, then proceed to Step 3.

---

### Step 3 — Extract Patterns

From the processed output, identify which of the 8 patterns are present:

```
Problem / Solution / Question / Observation→Hypothesis
Idea / Input (file reference) / Confusion / Combination
```

For Solution pattern — always check for:
- `Conditions:` — when this works
- `Limitations:` — when it does not work
- `Evidence:` — how you know

If Solution is present but Conditions or Limitations are missing: flag in quality review — *"Solution captured without conditions or limitations. Please add: under what circumstances does this work, and when does it not?"*

Record what was extracted. Proceed to Step 4.

---

### Step 4 — Rate Quality

Rate the quality of what was extracted in Step 3. Not the raw input — the extracted content.

| Rating | Criteria | Action |
|--------|----------|--------|
| **Excellent** | 2+ patterns; specific; linkable to 2+ topics; contextual; answerable | Process fully; generate 2 follow-up questions; suggest DECISIONS.md candidate if applicable |
| **Good** | 1 pattern; mostly clear; minor context gaps | Process normally; flag for enrichment in quality review |
| **Poor** | Genuinely vague after best-effort extraction; no linkable concepts; no actionable content | Do NOT ingest; write to `pending-quality-review.md` with reason AND a rewritten version using entry patterns |
| **Held** | Rapid style — not yet expanded | Not rated; move to `INBOX §Held`; expand at session close |

**Held is never Poor.** A Rapid entry becomes Good or Excellent after expansion.

---

### Step 5 — Create Links

Create typed wiki links based on what was extracted. Always create the strongest link type the evidence supports:

| Evidence Available | Link Type | Confidence |
|-------------------|-----------|------------|
| Explicit causal evidence (Problem + Solution with Evidence) | Causes | HIGH |
| Directional outcome without full evidence | Leads To | MEDIUM |
| Stated requirement (Depends On field or equivalent) | Depends On | MEDIUM–HIGH |
| Restriction or boundary stated | CONSTRAINS | MEDIUM |
| Connection without direction or causation | Related | LOW–MEDIUM |

Rules:
- All links are bidirectional in the wiki
- Prefer Causes / Leads To / Depends On over Related
- Never invent a Causes link when only Related is justified
- Document entries: create links between chunks AND between chunks and existing wiki topics
- Voice entries: same as Narrative after cleaning
- Held entries: no links created yet

---

### Step 6 — Route

Route extracted content to its outputs:

| Pattern | Routes To |
|---------|-----------|
| Problem | `wiki/topics/` · `INBOX §Open Questions` if unresolved |
| Solution | `wiki/topics/` · `SUCCESSES.md` stub |
| Question | `wiki/topics/` stub · `INBOX §Open Questions` |
| Observation→Hypothesis | `wiki/topics/` (MEDIUM confidence claim) |
| Idea | Typed link between two wiki topics |
| Input (file) | `wiki/topics/` extracted from referenced file |
| Confusion | `wiki/topics/` contradiction flag · `INBOX §Learning Triggers` |
| Combination | All applicable above |
| Held (Rapid) | `INBOX §Held` — awaiting session close |
| Document batch | Multiple routes, one per chunk |
| Decision detected | DECISIONS.md proposal at session close |
| Action detected | `ACTIONS.md` at session close |
| Achievement detected | `CAREER.md` at session close |
| Failure detected | `FAILURES.md` at session close |
| Success detected | `SUCCESSES.md` at session close |

After routing:
- Move processed entries to `INBOX §Processed`
- Snapshot any modified wiki page to `wiki/snapshots/`
- Update `wiki/topics/INDEX.md`
- Append to `log.md`

---

## Orphaned File Detection

Files in `raw/` or `raw-assets/` with no INBOX reference → flag in report. Learning trigger added: *"Reference or remove raw/[filename]"*. Do not process orphaned files.

---

## Report Format

```
INGEST REPORT — YYYY-MM-DD
Entries processed: [n]
  Styles detected: Structured: n / Narrative: n / Rapid: n / Document: n / Voice: n / Custom: n
  Ratings: Excellent: n / Good: n / Poor-rejected: n / Held: n
Patterns found: Problem: n / Solution: n / Question: n / Observation: n / Idea: n / Input: n / Confusion: n
Files processed: [n] (passed: n / rejected: n)
Orphaned files: [n] — [list]
Topics created: [list]
Topics updated: [list]
Links added: [n] (Causes: n / Leads To: n / Depends On: n / Related: n)
SUCCESSES.md stubs created: [n]
Held for session close: [n] — [fragments listed]
Pending review: outputs/pending-quality-review.md ([n] items)
```
