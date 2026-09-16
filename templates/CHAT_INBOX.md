# CHAT_INBOX.md — Chat Capture (V0.115)

Dedicated entry point for AI conversations. Processing rules → `reference/chat-input.md`.
Process weekly: `Follow agents.md. Process CHAT_INBOX.md`

**Every chat insight: confidence LOW, attributed to LLM and date, verified before wiki.**
Chat insights are suggestions, not sources. The LLM that produced the insight and the LLM processing this file are not the same thing — treat them independently.

---

## Entry Format

```markdown
## YYYY-MM-DD HH:MM | Conversation with [LLM name]
**Source:** API / Web / File
**Topic:** [one line]
**Confidence:** LOW

### Key Insights
- [insight] ([LLM name], [date])

### Possible Patterns Detected
- Problem: / Solution: / Question: / Observation: / Idea: / Confusion:
  (filled by LLM during processing — leave blank when capturing)

### Action Items
- [ ] Verify [insight] against primary sources

### Raw Transcript
raw/chat-transcripts/[filename].md
```

---

## Capture Methods

| Method | Command |
|--------|---------|
| Pipe | `echo "chat text" \| ~/kbs/scripts/chat-adapter.sh` |
| File | `~/kbs/scripts/chat-adapter.sh transcript.txt` |
| Webhook | `python3 ~/kbs/scripts/chat-api-adapter.py --server --port 8080` then POST to `/capture` |
| Manual | Paste using the format above |

---

## Unprocessed Conversations

*Add below. Nothing happens until you run the processing prompt.*

---

## Processed Conversations (LLM Moves Entries Here)
