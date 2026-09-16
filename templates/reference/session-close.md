# Reference: Session Close (V0.115)

Loaded when the owner runs: `Follow agents.md. Close session for [KB]`

---

## Pre-Close: Handle Pending Styles First

Before the 10-step close, resolve any entries that were not fully processed during ingestion:

### A — Expand Held Entries (Rapid Style)

For each entry in `INBOX §Held`:
1. Show the owner the fragment: *"You captured: '[fragment]' — what was the problem, solution, or insight? Add any context you can."*
2. Owner responds in chat
3. Treat response as Narrative input
4. Re-run through ingestion pipeline Steps 3–6 (style already resolved)
5. Remove from §Held; move to §Processed

One question per held entry. Do not batch held questions — ask them one at a time so the owner can answer specifically.

### B — Confirm Document Batches

For any Document-style entries processed during this session:
1. Show batch summary: *"Extracted [n] entries from your document: [list]. Confirm all, or tell me which to keep or discard."*
2. Owner confirms or adjusts
3. Apply confirmed entries; discard rejected ones
4. Log result

### C — Confirm Voice Extractions

For any Voice-style entries processed:
1. Show before/after if cleaning removed >20% of words
2. *"Cleaned your voice note. Extracted: [summary]. Does this capture what you meant?"*
3. Owner confirms or corrects
4. Apply confirmed content

### D — Confirm Custom Style Extractions

For any custom-style entries, show the extracted content and confirm with the owner before routing.

---

## The 10-Step Close

After pre-close is complete:

| # | Action | Ask the Owner | Output |
|---|--------|--------------|--------|
| 1 | Extract new concepts | "Any new ideas or topics from this session?" | Propose wiki pages |
| 2 | Write approved concepts as wiki pages | — | `wiki/topics/` |
| 3 | Capture problems | "What problems came up?" | Wiki topic + flag |
| 4 | Capture solutions | "What worked? Conditions? Limitations?" | `SUCCESSES.md` + wiki |
| 5 | Capture failures | "What went wrong or was predicted incorrectly?" | `FAILURES.md` |
| 6 | Capture decisions | "What choices did you make about approach, tools, or beliefs?" | Propose text for `DECISIONS.md` |
| 7 | Capture actions | "What will you do next session or by a specific date?" | `ACTIONS.md` |
| 8 | Add achievement | — at least one per close + suggest output template | `CAREER.md` |
| 9 | Flag open questions | — | `INBOX §Open Questions` |
| 10 | Cross-link, update log, produce report | — | wiki + `log.md` + chat |

### Implicit Failure Detection (Step 5 Enhancement)
During failure capture, compare newly documented problems against wiki topics with HIGH confidence upgraded in the last 90 days. If keywords, domain, and symptoms match a previously "solved" problem, flag: *"This looks like a recurring instance of [[topic]], which was upgraded to HIGH on [date]. Was the previous solution incomplete, or are the conditions different?"*

---

## Routing Logic for INBOX Entries at Close

When the owner has written in Narrative or has just expanded a Rapid entry:

```
Something that worked + evidence       → SUCCESSES.md + confidence upgrade
Something that failed or was wrong     → FAILURES.md + confidence downgrade
A choice made between alternatives     → DECISIONS.md proposal (owner pastes)
"will do" / "need to" / "by [date]"   → ACTIONS.md
A concept without clear type           → wiki topic
A question                             → INBOX §Open Questions
```

When ambiguous: ask one clarifying question. Never guess and route silently.

---

## Close Report Format

```markdown
## SESSION CLOSE REPORT — YYYY-MM-DD HH:MM
KB: [name]

### Held Entries Expanded
- "[fragment]" → [what it became after expansion]

### Document Batches Confirmed
- [n] entries from [document description]

### Voice Extractions Confirmed
- [summary of what was kept]

### New Wiki Pages
- [[topic]] — one-line summary

### Updated Wiki Pages
- [[topic]] — what changed

### Problems Captured
- [problem] → wiki

### Solutions Captured
- [solution] → SUCCESSES.md (conditions: [x] / limitations: [y])

### Failures Documented
- [failure] → FAILURES.md

### Decisions Proposed (owner pastes into DECISIONS.md)
- [decision text]

### Actions Created
- [action] due [date] → ACTIONS.md

### Career Update
- [achievement] → CAREER.md
- Suggested output template(s): [resume-bullet / interview-story / impact-metric]

### Open Questions (next session)
- [question] → INBOX §Open Questions

### Links Added
- [[A]] → [[B]] (Causes)

### Confidence Changes Proposed
- [[topic]] MEDIUM → HIGH (success evidence)
```

---

## CAREER.md Achievement Format (At Least One Per Close)

```markdown
## YYYY-MM-DD | [Title]
**Context:** [project / problem]
**Action:** [what was done — specific]
**Result:** [outcome — measurable if possible]
**Skills:** [tag1, tag2]
**LinkedIn bullet:** [one action-oriented sentence, quantified]
**Related:** [[wiki-topic]]
```

**Output template suggestion:** After writing the achievement, suggest which template(s) it fits:
- *Resume bullet:* one quantified line
- *Interview story:* STAR format paragraph
- *Impact metric:* skill-area table entry

Technical, process, and learning wins all count. The close is not complete without at least one.
