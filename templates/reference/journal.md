# Reference: Journal Operations (V11.4)

Loaded when the owner runs a chat prefixed with `Journal:` or `Follow agents.md. Process journal`

---

## Procedure

### When Owner Says "Journal: [text]"

1. **Save the entry**
   - Create `journal/YYYY-MM-DD-[slug].md`
   - Slug from a 3-5 word title inferred from contents
   - Format per `templates/JOURNAL.md`

2. **Read context**
   - `wiki/topics/INDEX.md` — find relevant topics
   - `journal/index.md` — find past entries on same themes
   - `CRM/index.md` — if exists, find relevant people
   - Read up to 5 most relevant wiki topics in full

3. **Grounded response**
   - Respond to the journal entry, not just acknowledge it
   - Cite specific wiki claims with confidence levels
   - Reference past journal entries if relevant
   - Include timestamps: "You saved [[video-title]] 3 days ago that says..."
   - Do NOT give generic advice — only advice that connects to saved knowledge

4. **Pattern detection**
   - Same theme in ≥3 entries over 30 days → flag as pattern
   - Same problem with no documented solution → flag for INBOX
   - Contradiction between journal sentiment and wiki claim → flag

5. **Update indices**
   - Append entry to `journal/index.md`
   - Update `log.md`

6. **Propose actions**
   - If pattern detected → propose ACTION entry
   - If new insight → propose wiki topic or INBOX entry
   - Write proposals to `outputs/pending-[date].md`

---

## Response Format

```
I'll treat this as a journal entry.

Reading wiki context: [[topic1]], [[topic2]], [[topic3]]...
Past journal entries on this theme: [list or none]

[JOURNAL RESPONSE]

Pattern detected: [yes/no — if yes, describe]
Suggested actions: [list or none]
```

---

## Boundaries

- Never detect human qualities (honesty, courage, love, emotions, wisdom)
- Never make therapeutic claims or diagnose
- Never write journal entries — owner writes, LLM responds
- Never delete journal entries
- Always ground responses in wiki content when possible
