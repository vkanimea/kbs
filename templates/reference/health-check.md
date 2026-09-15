# Reference: Health Check (V11.3)

Loaded when the owner runs: `Follow agents.md and SYSTEM.md. Run health check on [KB]`

Health checks **propose only**. Never execute without approval (Level 0–1; Level 2+ per SYSTEM.md §Autonomous Policies).

---

## Checks to Run

### Structure
- **Orphan topics:** 0 incoming AND 0 outgoing links → list each
- **Orphan assets:** files in `raw/` or `raw-assets/` with zero INBOX references → list each
- **Orphan rate:** orphans ÷ total topics (target <5%)
- **Average links per topic** (target >2.0)
- **Overuse of `Related`:** topics where >70% of links are Related → suggest typed upgrades
- **Missing Conditions:** HIGH confidence claims with no Conditions column entry → flag each
- **Topic aging:** For KBs with >50 topics, review `last queried` dates. Flag topics unqueried >90 days with relevance score not set.
- **Archive candidates:** Topics unqueried >180 days, LOW relevance, no incoming links from HIGH claims → propose archive to `wiki/archive/`

### Quality
- **Contradictions:** unresolved §Contradictions across all wiki pages
- **Stale LOW confidence:** topics older than 90 days with no upgrade → propose review or archive
- **Solutions without conditions:** SUCCESSES.md entries missing Conditions or Limitations → flag

### Failures (read FAILURES.md)
- Entries `Resolved: No` older than 30 days
- Topics with ≥2 confidence downgrades in 90 days → pattern flag
- Zero failures documented this month → note possible under-reporting
- **Implicit failure detection:** Compare INBOX entries from last 30 days against wiki topics upgraded to HIGH in last 90 days. If the same problem pattern reappears (similar keywords, same domain, same symptoms) despite a prior solution, flag: *"Recurring problem detected — [[topic]] was upgraded to HIGH but the same pattern reappeared in INBOX. Was the solution incomplete?"*

### Successes (read SUCCESSES.md)
- Entries `Repeatable: Unknown` older than 30 days → flag for owner assessment
- Success-to-failure ratio (target: neither vastly outnumbers the other; imbalance signals under-reporting of one type)
- Claims upgraded to HIGH → verify they have Conditions in the wiki topic

### Actions (read ACTIONS.md)
- Open actions older than 14 days → flag
- Completed actions with no outcome routed → flag
- Actions blocked by unresolved failures → flag connection

### INBOX Quality (last 30 days from §Processed ratings)
- Excellent rate (target >50%) / Poor-rejection rate (target <20%)
- Pattern distribution — flag if one pattern dominates (signals narrow thinking)
- Solution pattern frequency — solutions should roughly match problems over time
- Held entry age — any held >7 days = missed close

### Career (read CAREER.md)
- Achievements this month; flag zero-achievement month
- Skill-tag frequency table
- Solutions documented vs problems documented ratio
- Achievement output templates usage: resume-bullets, interview-stories, impact-metrics

---

## Outputs

1. `outputs/health-check-[date].md` — full report with all metrics
2. `outputs/pending-[date].md` — numbered proposals for batch approval:
   - Missing typed links to add
   - Topics to archive
   - Assets to delete or reference
   - Contradictions needing owner resolution
   - Solutions needing conditions/limitations
3. Learning triggers appended to `INBOX.md`
4. One line appended to `log.md`
5. Suggest 3 ingestion candidates based on detected gaps

---

## Report Skeleton

```
HEALTH CHECK — YYYY-MM-DD | KB: [name]
Topics: [n] | Orphan rate: [x]% | Avg links: [x]
Contradictions: [n] | Stale LOW: [n] | HIGH without conditions: [n]
Failures unresolved >30d: [n] | Downgrade patterns: [n] | Recurring problems: [n]
Successes Repeatable:Unknown >30d: [n] | Success/failure ratio: [x:y]
Actions overdue: [n] | Actions unrouted: [n]
INBOX 30d: Excellent [x]% / Poor [x]% | Dominant pattern: [name or balanced]
Solutions documented: [n] | Problems documented: [n]
Career: [n] achievements this month | Top skill: [tag]
Topic aging: HIGH [n] | MEDIUM [n] | LOW [n] | Archive candidates: [n]
Proposals: outputs/pending-[date].md ([n] items)
```
