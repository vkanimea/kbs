# Root Cause Analysis

TLDR: Identifying the underlying assumption that failed, not just the symptom that appeared. The "wrong assumption" field in FAILURES.md is the root cause in textual form.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Documenting wrong assumptions prevents recurrence | MEDIUM | Owner reviews failures monthly | [[failure-learning]] |
| 5 Whys method complements KBS failure format | MEDIUM | Problem has sequential causes | [[success-validation]] |

## Typed Relationships
### Causes
- [[root-cause-analysis]] Causes [[confidence-scoring]] (downgrades on disproven claims)

### Leads To
- [[root-cause-analysis]] Leads To [[solution-pattern]]

### Depends On
- [[root-cause-analysis]] Depends On [[failure-learning]] (needs documented failures)

### Related
- [[problem-solving]]
- [[decision-records]]

## Open Questions
- At what point does root cause analysis become overthinking?
