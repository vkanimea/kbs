# INBOX.md — Capture Stream (V0.113)

The default entry point for everything. Just write — the system detects your input style automatically and processes it correctly. No prefix required.

For AI conversations → `CHAT_INBOX.md` · For urgent failures → `FAILURES.md` · For urgent wins → `SUCCESSES.md`

---

## Just Write — The System Adapts to You

The LLM reads SYSTEM.md §Style Registry before processing anything here. It detects which of the 5 built-in styles (or any custom style you have registered) your entry is, and applies the right processing automatically.

```
You used pattern labels          → Structured  — processed directly
You wrote in sentences           → Narrative   — patterns inferred
You captured a quick fragment    → Rapid       — held, expanded at session close
You pasted a full document       → Document    — split into chunks, batch confirmed
Your entry is a voice transcript → Voice       — cleaned, then processed
You defined a custom style       → Custom      — processed per your definition
```

**You never need to label your style.** Just write the way that fits the moment.

---

## The 8 Patterns (Use When You Have Time — Optional Otherwise)

```markdown
Problem:      [specific issue + context of where and when]

Solution:     [what was done]
Solves:       [which problem]
Conditions:   [when this works — be specific]
Limitations:  [when it does NOT work]
Evidence:     [how you know — data or observation]

Question:     [what you want to understand — specific and answerable]

Observation:  [what you noticed — concrete]
Hypothesis:   [why you think it happens — testable]

Idea:         [connection between two concepts, especially across domains]

PDF:          [filename] — [what to extract]
MD:           [filename] — [what to extract]
TXT:          [filename] — [what to extract]
CSV:          [filename] — [what to extract]

Confusion:    [what does not make sense or contradicts expectations]
```

Using patterns gives the richest wiki output. But any style — including a one-line fragment — is accepted.

---

## Input Examples

<!-- EXAMPLE — delete this block after reading. These are demo entries showing each style in action. -->

```markdown
### 2026-06-11 09:00  ← Structured (Gold Standard)
Problem: SharePoint search returns irrelevant results after migration.
Observation: Users opening 3–4 results before finding right document.
Hypothesis: Metadata not mapped correctly during migration.
Solution: Forced full crawl after verifying metadata mapping.
Conditions: Metadata must be mapped before crawl runs.
Limitations: Does not fix gaps in source metadata.
Evidence: Relevance up 40%. Click depth dropped from 4 to 1.2.
Question: What other ranking signals can be tuned post-migration?

### 2026-06-11 14:30  ← Narrative (auto-detected)
The crawl fixed the relevance issue after we mapped metadata first.
40% improvement. Need to check what other signals affect ranking.

### 2026-06-11 16:45  ← Rapid (auto-detected — held until session close)
metadata before crawl — not after

### 2026-06-11 17:00  ← Document (auto-detected — split into chunks)
Meeting — Search Project Review
Attendees: Sarah, James, Dev team
Problem: Users still clicking too many results after migration
Decision: Run monthly crawl audit going forward
Action: James to document crawl schedule config by Friday
Open question: Do managed metadata columns affect ranking weight?
Next steps: Pilot test with 10 users after next crawl cycle

### 2026-06-11 17:30  ← Voice transcript (auto-detected — cleaned)
So um, the crawl, the crawl fixed it right, like after we — after we
mapped the metadata first. Um the relevance went up like 40% I think.
Need to check what other signals, you know, what other ranking signals
we can tune after the migration.
```

---

## File Formats

| You write | File location |
|-----------|--------------|
| `PDF: file.pdf — extract...` | `raw-assets/pdfs/file.pdf` |
| `MD: file.md — extract...` | `raw/file.md` |
| `TXT: file.txt — extract...` | `raw/file.txt` |
| `CSV: file.csv — extract...` | `raw/file.csv` |

Office files (.docx, .pptx, .xlsx) → convert to PDF first.
Audio/video → transcribe to .txt first.

---

## Quick Capture

```bash
# Linux/macOS
echo -e "### $(date '+%Y-%m-%d %H:%M')\n" >> ~/kbs/INBOX.md

# Shell alias — type 'kbs' anywhere
alias kbs='echo -e "### $(date +\"%Y-%m-%d %H:%M\")\n" >> ~/kbs/INBOX.md && nano ~/kbs/INBOX.md'
```

```powershell
# Windows
Add-Content "$env:USERPROFILE\kbs\INBOX.md" "### $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
```

---

## Custom Styles

If you have a recurring input type not covered by the 5 built-in styles, define it in SYSTEM.md §Style Registry. Once registered, the LLM detects and processes it automatically — no prefix needed.

See SYSTEM.md §Custom Styles for the definition template and examples.

---

## Unprocessed Entries

*Add new entries below. Run `Follow agents.md. Ingest main` to process.*

---

## Held Entries (Rapid — Expanded at Session Close)

*LLM moves Rapid entries here. Owner expands at session close.*

---

## Open Questions (Auto-Populated by Session Close)

---

## Processed Entries (LLM Moves Entries Here — Do Not Edit)
