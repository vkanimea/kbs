# Backup Strategy

TLDR: KBS is plain markdown + git — inherently recoverable. The minimum backup is `tar` or `git push`. Snapshots in `wiki/snapshots/` provide point-in-time recovery for individual topics.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Plain text + git survives any technology change | HIGH | Git remote is maintained | [[success-validation]] |
| Snapshots enable topic-level rollback | MEDIUM | Snapshots are created after every ingest | [[failure-learning]] |

## Typed Relationships
### Causes
- [[backup-strategy]] Causes [[monthly-health-check]] (safety for audits)

### Leads To
- [[backup-strategy]] Leads To [[session-management]] (confidence to experiment)

### Depends On
- [[backup-strategy]] Depends On [[knowledge-capture]] (needs something to back up)

### Related
- [[document-processing]]
- [[confidence-scoring]]

## Open Questions
- What is the optimal snapshot retention policy?
