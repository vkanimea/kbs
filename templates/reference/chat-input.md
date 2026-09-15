# Reference: Chat Input Processing (V0.113)

Loaded when the owner runs: `Follow agents.md. Process CHAT_INBOX.md`

---

## Rules

1. **Attribute every insight:** "Claude suggested X (2026-06-09)" — never "X is true".
2. **Default confidence = LOW.** Chat is a suggestion, not a source.
3. **Upgrade confidence only when corroborated** by a non-chat source already in the wiki.
4. **Flag contradictions** with existing wiki pages — list them; never auto-resolve.
5. **Propose, don't add.** At Level 0–1 every wiki addition from chat needs approval.

---

## Procedure

1. Read unprocessed entries in `CHAT_INBOX.md`
2. For each conversation: extract distinct insights (not a transcript dump)
3. Check each insight against existing wiki topics:
   - Corroborates → note "supports [[topic]]"
   - Contradicts → flag in report; add to topic's §Contradictions only after approval
   - New → propose a topic stub
4. Write proposals to `outputs/pending-[date].md`
5. Ask the owner which insights to add
6. After approval: apply, move entries to §Processed, append to `log.md`

---

## Report Format

```
CHAT INGEST REPORT — YYYY-MM-DD
Conversations processed: [n]
Insights extracted: [n]
  Corroborating existing topics: [n]
  Contradicting existing topics: [n] — [list]
  New topic proposals: [n] — [list]
Awaiting approval: outputs/pending-[date].md
```

---

## Confidence Lifecycle for Chat Insights

```
Chat insight (LOW)
  → corroborated by independent source → MEDIUM
  → corroborated by 2+ sources / survives failure review → HIGH
  → contradicted → stays LOW, flagged
```
