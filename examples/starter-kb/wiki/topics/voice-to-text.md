# Voice to Text

TLDR: Transcribed voice notes contain filler words, false starts, and repetition. The Voice style strips noise while preserving all substantive content, then processes the cleaned text as Narrative.

## Key Claims
| Claim | Confidence | Conditions | Source |
|-------|------------|------------|--------|
| Voice cleaning preserves >95% of substantive content | MEDIUM | Transcription quality is adequate | [[success-validation]] |
| Voice capture is 3-5x faster than typing for mobile | LOW | Measured anecdotally; varies by speaker | [[knowledge-capture]] |

## Typed Relationships
### Causes
- [[voice-to-text]] Causes [[knowledge-capture]] (mobile input)

### Leads To
- [[voice-to-text]] Leads To [[rapid-capture]] (voice notes often fragmentary)

### Depends On
- [[voice-to-text]] Depends On [[knowledge-capture]] (needs transcription)

### Related
- [[document-processing]]
- [[async-communication]]

## Open Questions
- What is the best open-source Whisper pipeline for local transcription?
