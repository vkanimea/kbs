# Solution Pattern

TLDR: Every documented solution must include Conditions (when it works), Limitations (when it does not), and Evidence (how you know). Without these three, a solution is an overconfident claim waiting to mislead.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Conditions prevent misapplication | HIGH | Solution is reused in a new context | [[failure-learning]] |
| Evidence requirement upgrades confidence legitimately | HIGH | Evidence is specific, not anecdotal | [[success-validation]] |

## Typed Relationships
### Causes
- [[solution-pattern]] Causes [[success-validation]] (structured success entry)
- [[solution-pattern]] Causes [[confidence-scoring]] (upgrade path)

### Leads To
- [[solution-pattern]] Leads To [[decision-records]] (reusable reasoning)

### Depends On
- [[solution-pattern]] Depends On [[problem-solving]] (needs defined problem)

### Related
- [[knowledge-capture]]
- [[cross-domain-ideas]]

## Contradictions
- Agile/lean advocates sometimes argue "just try it" over documentation — KBS argues the cost of rediscovery exceeds documentation cost after the third occurrence.

## Open Questions
- What is the minimum viable evidence for a LOW-confidence solution?
