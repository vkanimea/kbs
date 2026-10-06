# Reference: Writing Style (V0.117)

Loaded when the librarian **writes prose** — wiki topics, lesson outputs, query syntheses,
reports. Not for captures (INBOX entries are the owner's words) and not for the system
files themselves.

The goal: wiki prose that a human wants to read, and that doesn't read like a machine
wrote it. Adapted from the `stop-slop` skill (amosblomqvist/pi-config) and applied to KBS
outputs.

---

## Why this matters for KBS

Wiki pages are read *by the owner, later*, often years later. AI prose has recognizable
tells that erode trust and blur meaning: filler that says nothing, binary contrasts that
argue with a strawman, metronomic rhythm that hides which claim matters. A wiki is only as
useful as it is readable, and a claim buried in throat-clearing is a claim half-lost.

Write so the owner can see the *content* — the claim, its confidence, its conditions — and
not the writing.

---

## The rules

1. **Cut filler.** No throat-clearing openers, no emphasis crutches, no adverbs doing no
   work. Start with the claim.
2. **Break formulaic structures.** No "not X, but Y" contrasts; state Y. No negative
   listings, no dramatic one-line fragments, no rhetorical setups.
3. **Use active voice.** A subject doing something. No inanimate objects performing human
   verbs ("the failure becomes a lesson").
4. **Be specific.** Name the thing. "The reasons are structural" says nothing — say which
   reason. Avoid vague extremes ("every," "always," "never") standing in for precision.
   (Note: in the *Claims table* precision is mandatory anyway — a HIGH claim needs its
   conditions.)
5. **Put the reader in the room.** "You" beats "one" or "people." Concrete beats abstract.
6. **Vary rhythm.** Mix sentence lengths. Two items beat three. No em dashes.
7. **Trust the reader.** State facts directly; skip softening and hand-holding.
8. **Cut quotables.** If a sentence reads like a pull-quote, rewrite it.

---

## Quick checks before writing a wiki page or lesson output

- Any adverbs? Cut them.
- Passive voice? Find the actor; make them the subject.
- Inanimate thing doing a human verb? Name the person.
- Sentence starts with a Wh- word? Restructure.
- "Here's what/this/that" throat-clearing? Cut to the point.
- "Not X, it's Y"? State Y.
- Three consecutive sentences the same length? Break one.
- Paragraph ends on a punchy one-liner? Vary it.
- Em dash? Remove it.
- Vague declarative? Name the specific thing.
- Meta-joiner ("The rest of this page…")? Delete; let the page move.

---

## What is *not* affected

- **Claims table, conditions, confidence** — structured data, not prose. Precedence: the
  claims table is the substance; the prose around it exists to orient, not to decorate.
- **Captures** — INBOX entries preserve the owner's own words. Do not rewrite them into
  house style (the style registry handles their processing).
- **System files** — agents.md, SYSTEM.md, and `reference/*` are written terse and
  precise by design; this guide governs *generated content*, not the system.
- **Accuracy outranks style, always.** A cleaner sentence that drops a condition or a
  source is worse, not better. Style never overrides the confidence/conditions rules.
