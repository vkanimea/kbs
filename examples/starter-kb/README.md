# KBS Starter Knowledge Base

A pre-built example knowledge base with 20 cross-linked topics demonstrating KBS conventions. Use this to understand how topics are structured, how typed relationships work, and how confidence levels are maintained.

## How to Use

### Option 1: Browse as Reference
Open `wiki/topics/` and read any topic. Notice:
- The **TLDR** at the top
- The **Key Claims** table with Confidence, Conditions, and Source columns
- The **Typed Relationships** sections (Causes, Leads To, Depends On, Related)
- **Contradictions** and **Open Questions**

### Option 2: Adopt as Your Starting KB
Copy the contents of this directory into your KBS wiki:

```bash
cp -r examples/starter-kb/wiki/topics/* ~/kbs/kb/main/wiki/topics/
```

Then run a query to see the system in action:
```
Follow agents.md. Query main: What causes attention residue and how does KBS address it?
```

### Option 3: Learn by Modifying
Pick a topic and add a new claim, link, or contradiction. Run ingestion and watch how the INDEX and links update.

## Topics Included (22)

### Rituals & Habits
- [[session-management]] — the core ritual
- [[daily-review]] — morning query habit
- [[weekly-ingestion]] — batch processing ritual
- [[monthly-health-check]] — comprehensive audit

### Knowledge Work
- [[problem-solving]] — root methodology
- [[root-cause-analysis]] — finding wrong assumptions
- [[solution-pattern]] — conditions + limitations + evidence
- [[confidence-scoring]] — LOW/MEDIUM/HIGH tracking

### Capture & Input
- [[knowledge-capture]] — front door of the system
- [[rapid-capture]] — fragments held for expansion
- [[voice-to-text]] — transcribed audio processing
- [[document-processing]] — chunking long documents

### Learning & Memory
- [[spaced-repetition]] — scientific basis for review cycles
- [[failure-learning]] — double-loop learning
- [[success-validation]] — conditional success documentation
- [[cross-domain-ideas]] — creative recombination

### Communication
- [[async-communication]] — written reasoning
- [[meeting-notes]] — structured capture
- [[decision-records]] — human judgement log

### Technical Operations
- [[backup-strategy]] — plain text resilience
- [[context-switching]] — cognitive cost
- [[attention-residue]] — deep work enemy

## Link Statistics
- 22 topics
- ~70 typed links (Causes, Leads To, Depends On, Related)
- 8 contradictions documented
- 15 open questions flagged

## Next Steps
After exploring this starter KB, begin replacing topics with your own domain knowledge. Keep the structure — TLDR, Key Claims, Typed Relationships, Contradictions, Open Questions — and the system will maintain itself.
