# KBS Audit Log — Append-Only (V0.115)

Never edit or delete entries. One line per event, formats below.

```
[ts] INGEST | KB | FILES: ... | passed/failed | TOPICS: n | LINKS: n
[ts] QUERY | KB | "question" | TOPICS_USED: ... | OUTPUT: file | COMPOUNDED: y/n
[ts] CHAT_INGEST | KB | SOURCE: llm | INSIGHTS: n | ADDED: n | CONTRADICTIONS: n
[ts] FAILURE_PROCESS | KB | FAILURES: n | DOWNGRADES: n
[ts] SESSION_CLOSE | KB | TOPICS: +n/~n | LINKS: n | DECISIONS: n | FAILURES: n | ACHIEVEMENTS: n
[ts] APPROVAL | KB | APPROVED: ... | REJECTED: ... | REASON: "..."
[ts] HEALTH_CHECK | KB | ORPHANS: n | CONTRADICTIONS: n | RATE: x% | PENDING: file
[ts] AUTO_ACTION | KB | ACTION | TARGET | POLICY | REVERSIBLE: y/n
[ts] FAILURE_CONTAINMENT | TRIGGER | LEVEL: n→n | REVIEW: file
```

---

## Log
