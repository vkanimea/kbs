# Monthly Health Check

TLDR: A comprehensive audit of knowledge base health — orphan rate, link density, stale claims, unresolved failures, and overdue actions. Proposes corrections but never executes without approval.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Monthly checks maintain <5% orphan rate | HIGH | Check runs within 35 days of previous | [[success-validation]] |
| Health checks detect under-reporting | MEDIUM | Owner is honest about failures and successes | [[failure-learning]] |

## Typed Relationships
### Causes
- [[monthly-health-check]] Causes [[root-cause-analysis]] (when patterns emerge)

### Leads To
- [[monthly-health-check]] Leads To [[confidence-scoring]] (recommendations)

### Depends On
- [[monthly-health-check]] Depends On [[weekly-ingestion]] (needs processed entries)
- [[monthly-health-check]] Depends On [[backup-strategy]] (safety before audit)

### Related
- [[session-management]]
- [[decision-records]]

## Contradictions
- Frequent audits may discourage capture if owner fears judgment — mitigated by "propose only" policy.

## Open Questions
- What is the optimal health check frequency for 100+ topic KBs?
