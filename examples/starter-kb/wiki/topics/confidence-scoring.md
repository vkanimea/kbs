# Confidence Scoring

TLDR: LOW / MEDIUM / HIGH are not opinions — they are tracked beliefs updated by evidence. SUCCESSES.md upgrades; FAILURES.md downgrades. Both require explicit documentation.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Confidence tracking prevents overconfidence | HIGH | Both successes and failures are documented | [[failure-learning]] |
| HIGH claims require conditions column | HIGH | Claim is used for decision-making | [[success-validation]] |
| Downgrades are as valuable as upgrades | MEDIUM | Owner does not hide failures | [[monthly-health-check]] |

## Typed Relationships
### Causes
- [[confidence-scoring]] Causes [[decision-records]] (informs choices)

### Leads To
- [[confidence-scoring]] Leads To [[monthly-health-check]] (metrics)

### Depends On
- [[confidence-scoring]] Depends On [[success-validation]]
- [[confidence-scoring]] Depends On [[failure-learning]]

### Related
- [[problem-solving]]
- [[solution-pattern]]

## Open Questions
- Should confidence have a time-decay factor for old HIGH claims?
