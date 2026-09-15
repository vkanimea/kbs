# JOURNAL.md — Reflective Capture (V0.113)

A journal entry is not an INBOX item. It is a reflective conversation with the system. The LLM reads the wiki, past journal entries, and the CRM (if present) to ground its response in your accumulated knowledge.

**Auto-populated by:** chat prefixed with `Journal:` or explicit `Process journal`
**Review weekly** alongside INBOX processing.

---

## Entry Template

```markdown
## YYYY-MM-DD | [Short title based on contents]
**Mood:** [optional — one word]
**Topics:** [tag1, tag2]

### Entry
[Your reflective writing — any style, any length]

### System Response
[LLM response grounded in wiki + past journals + CRM]

### Synthesis
[Patterns detected, related wiki topics, suggested actions]

### Related
- [[wiki-topic]]
- [[past-journal-entry]]
```

<!-- EXAMPLE — delete this block after reading -->
```markdown
## 20XX-01-15 | Creative block on video titles
**Mood:** frustrated
**Topics:** content-creation, decision-making

### Entry
I have tons of video ideas but I avoid making them because I worry they won't get views. I know how to write clickbait titles but I hate them. I make literal titles instead and get fewer views. This is a constant struggle.

### System Response
Two fears are braided here: creative integrity and channel safety. The vault has creator-strategy pages that frame visible metrics as lagging indicators. A few lower-view videos are not a downward spiral. Consider: what would you title this video if you knew nobody would watch it? Start there.

### Synthesis
- Recurring pattern: fear-of-judgment vs authenticity (3rd journal entry on this)
- Wiki claim: "YouTube's value-of-death rewards persistence over viral hits" — HIGH confidence
- Suggested action: A/B test one "honest" title vs one "optimized" title this week

### Related
- [[creator-persistence]]
- [[youtube-value-of-death]]
- [[20XX-01-08-title-anxiety]]
```
<!-- END EXAMPLE -->

---

## How It Differs from INBOX

| | INBOX | Journal |
|---|---|---|
| Purpose | Capture facts, problems, solutions | Reflect, process emotions, seek insight |
| Style | Any of 5 built-in + custom | Narrative or Rapid, then expanded |
| LLM role | Extract, categorize, link | Read context, ground response, detect patterns |
| Output | Wiki topics, SUCCESSES.md, ACTIONS.md | Journal entry + pattern flags + suggested actions |
| Review cycle | Weekly ingestion | Weekly pattern review |

---

## Journal Entries

*Newest first. Auto-populated by journal operations.*
