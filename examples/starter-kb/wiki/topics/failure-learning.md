# Failure Learning

TLDR: Documenting failures with the wrong assumption identified is double-loop learning — it changes the underlying model, not just the outcome. Failures are permanent records; never deleted.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Documented failures prevent recurrence | MEDIUM | Owner reviews failures monthly | [[success-validation]] |
| Wrong-assumption field is the critical differentiator | HIGH | Compared to systems that only log outcomes | [[root-cause-analysis]] |
| Failure under-reporting signals ego protection | MEDIUM | Zero failures in 30 days for active project | [[monthly-health-check]] |

## Typed Relationships
### Causes
- [[failure-learning]] Causes [[confidence-scoring]] (downgrades)
- [[failure-learning]] Causes [[root-cause-analysis]]

### Leads To
- [[failure-learning]] Leads To [[decision-records]] (lessons inform future choices)

### Depends On
- [[failure-learning]] Depends On [[knowledge-capture]] (needs honest documentation)

### Related
- [[success-validation]]
- [[problem-solving]]

## Contradictions
- Corporate cultures often punish failure documentation — KBS is designed for personal/private use where honesty is safer.

## Open Questions
- How to handle failures that are emotionally difficult to document?
