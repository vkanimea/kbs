# KBS Glossary

| Term | Definition |
|------|-----------|
| **Activity Level** | A graduated trust tier (0–3) controlling what the agent can do: read-only (0), append (1), execute scripts (2), full write + network (3). See `docs/security.md`. |
| **Agent harness** | A tool that gives an LLM shell access, file read/write, and script execution (e.g., Claude Code, pi, Aider). Required for Activity Levels 2–3. |
| **Chat client** | A web or desktop LLM interface (Claude.ai, ChatGPT) that can read/write files but cannot run scripts or push git. Caps at Activity Level 1. |
| **Close / Session close** | The end-of-session procedure that expands held entries, confirms batches, routes everything, and compounds insights into wiki, decisions, and failures. |
| **Compounding** | The cumulative effect of each session close adding structured knowledge to the wiki, so later sessions start from a richer base. |
| **Confidence** | A three-level rating (HIGH / MEDIUM / LOW) on wiki claims, upgraded by successes and downgraded by failures. |
| **Held** | An INBOX entry deferred for later expansion (typically Rapid-style entries). Not rated until expanded. |
| **Librarian** | The agent persona: organizes, links, and expands knowledge. Does not judge, delete, or make trade-offs without approval. |
| **Quality gate** | The ingestion step that rates extracted content (Excellent / Good / Poor / Held) and rejects Poor entries with a rewrite suggestion. |
| **Session analysis** | Mining agent history (cost, struggles, repeated prompts) for patterns. See `reference/session-analysis.md`. |
| **Style Registry** | The set of input formats (Structured, Narrative, Rapid, Document, Voice, Custom) defined in `SYSTEM.md` that determine how an INBOX entry is processed. |
| **Tutor** | The teaching mode (`Teach me [KB]: [topic]`) that walks the owner through a topic using wiki content. |
| **Typed relationship** | A semantic link between wiki topics: Causes, Leads To, Depends On, or Related. Enables causal queries, not just link traversal. |
