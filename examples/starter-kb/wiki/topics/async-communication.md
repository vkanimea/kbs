# Async Communication

TLDR: Asynchronous communication (email, Slack, documented decisions) produces better reasoning than synchronous because it allows reflection before response. KBS captures async outputs as Document-style entries.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Async decisions are higher quality than meeting decisions | MEDIUM | Decision is non-urgent and complex | [[success-validation]] |
| Written reasoning preserves context for future queries | HIGH | Document is linked to relevant wiki topics | [[knowledge-capture]] |

## Typed Relationships
### Causes
- [[async-communication]] Causes [[decision-records]] (written reasoning)

### Leads To
- [[async-communication]] Leads To [[meeting-notes]] (meetings become shorter)

### Depends On
- [[async-communication]] Depends On [[document-processing]] (email threads, Slack exports)

### Related
- [[knowledge-capture]]
- [[voice-to-text]]

## Contradictions
- Urgent decisions require sync — async has a latency cost. KBS does not dispute this; it captures the async reasoning after the fact.

## Open Questions
- What is the optimal async/sync ratio for different team sizes?
