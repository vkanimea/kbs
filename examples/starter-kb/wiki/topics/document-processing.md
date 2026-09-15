# Document Processing

TLDR: Long documents, meeting notes, and email threads are split into logical chunks at paragraph or section boundaries. Each chunk is processed independently, rated independently, and linked both to existing topics and to other chunks.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Chunking preserves more context than summarizing | MEDIUM | Sections are logically coherent | [[success-validation]] |
| Batch confirmation prevents false positives | HIGH | Owner reviews extracted entries | [[failure-learning]] |

## Typed Relationships
### Causes
- [[document-processing]] Causes [[weekly-ingestion]] (batch material)

### Leads To
- [[document-processing]] Leads To [[meeting-notes]]

### Depends On
- [[document-processing]] Depends On [[knowledge-capture]] (source material)

### Related
- [[voice-to-text]]
- [[async-communication]]

## Open Questions
- What is the optimal chunk size for different document types?
