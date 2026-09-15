# Reference: Actions Processing (V0.114)

Loaded when the owner runs: `Follow agents.md. Process ACTIONS.md`
Also checked automatically during every session close.

---

## Procedure

### During Session Close
1. Scan ACTIONS.md for entries with `Done: Yes` that have no outcome routed yet
2. For each completed action: read the Outcome field
3. Route the outcome:
   - Positive outcome → propose SUCCESSES.md entry
   - Negative outcome → propose FAILURES.md entry
   - Mixed → propose both with separate lessons
4. Link the completed action to the wiki topic it created or updated (if any)
5. Move entry to §Completed Actions section

### During Explicit Processing
1. List all open actions (`Done: No`)
2. Flag any older than 14 days → learning trigger in INBOX.md
3. Flag any with `Due` date passed → ask owner for status
4. Check if any open actions are blocked by unresolved failures → flag connection

---

## Report Format

```
ACTIONS REPORT — YYYY-MM-DD
Open actions: [n]
  Overdue (>14 days): [n] — [list]
  Due this week: [n] — [list]
Completed since last check: [n]
  Routed to SUCCESSES.md: [n]
  Routed to FAILURES.md: [n]
Blocked by unresolved failures: [n]
```
