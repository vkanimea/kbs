# Reference: Learning Operations (V0.117)

Loaded when the owner runs one of:

- `Follow agents.md. Teach me [KB]: [topic]` — **wiki-only mode** (default)
- `Follow agents.md. Teach me [KB]: [topic] — from sources` — **bootstrap mode** (explicit override)

This is the **tutor** side of KBS. The librarian organises and preserves knowledge
(agents.md); this operation **teaches from it**. The wiki is the library, the lesson
is the transfer into the owner's head.

Teaching is always **opt-in and owner-invoked** (rule 1: passive by default). Never
begin a lesson without the explicit `Teach me [KB]:` prompt. Never teach from memory
alone — teach from the wiki, and verify every claim against it.

---

## The Two Modes

Teaching is a **decision**, not an inference: the owner picks the mode in the prompt, and
the tutor never silently chooses for them. This mirrors how KBS handles other
safe-default-vs-explicit-override choices (e.g. `KBS_DRIFT_GUARD=off`).

| | **Wiki-only** (default) | **Bootstrap** (`— from sources`) |
|---|---|---|
| Prompt | `Teach me [KB]: [topic]` | `Teach me [KB]: [topic] — from sources` |
| Source of truth | The wiki, and nothing else | Wiki first, external research for genuine gaps |
| Topic not in the wiki | **Refuse to teach it** — capture a Question and stop | Research it, teach it, and **capture every asserted claim** |
| KBS rule posture | Pure: teaching reads the library (rule 6, rule 8) | Explicit owner-authorised exception; provenance is marked and captured |

**Why the default is strict.** The wiki is the system's grounded source of truth. A fact
researched mid-lesson and spoken but never captured is a claim with no confidence level,
no conditions, and no source — exactly what rule 6 (scope before ingestion) and rule 8
(chat insights are suggestions, not sources) exist to prevent. So the *default* must not
introduce ungrounded knowledge. When the owner wants to learn something the library does
not yet hold, that is a real and useful thing to do — but it is a deliberate exception,
and it is paid for by mandatory capture (below).

**Mode is never inferred.** If the prompt does not say `— from sources`, run wiki-only.
Do not upgrade to bootstrap because the wiki is thin; that is the owner's call.

---

## What This Is (and Is Not)

- **Is:** a structured teaching session that reads the wiki, plans a dependency graph,
  teaches node by node, checks understanding with `quiz`, and captures what was
  learned back into KBS.
- **Is not:** an open-ended "explain anything" tutor. In wiki-only mode it teaches only
  what the wiki grounds. The unrestricted tutor from the `learn` package is reachable
  only via the explicit bootstrap override.
- **Is not:** a substitute for ingestion. You do not create wiki claims here — you
  *read* them. New claims discovered during a lesson are **captured** (INBOX / open
  questions / Confusion flags), then processed by ingestion later.
- **Is not:** autonomous. It never runs on a schedule. One explicit prompt, one lesson.

The teaching philosophy below is adapted from the `learn` package's `teach` skill:
two principles, a fixed three-phase shape, and the quiz-option construction procedure.

---

## Non-Negotiables

1. **Teach from the wiki, not from memory.** The moment you are even slightly unsure of
   a fact, name, date, formula, definition, or claim, stop and check the wiki. Working
   from memory is where LLMs invent things, and one confidently-delivered hallucination
   poisons the owner's trust.
2. **Wiki confidence is not the same axis as "unconditional truth."** Confidence
   (HIGH/MEDIUM/LOW + conditions) measures *epistemic reliability*. An "unconditional
   truth" measures *whether the fact is safe to accept at face value without caveats*.
   They overlap but are not the same. **Only a claim that is HIGH-confidence AND
   condition-free may be presented as an unconditional truth.** Everything else must
   travel the motivated "how could I have discovered this?" path.
3. **Never present a Solution-pattern claim as settled without its conditions.**
   A HIGH claim with conditions is conditional knowledge — teach it with its
   conditions, or it is wrong by omission.
4. **You propose; the owner decides** (rule 2). Lessons may *propose* confidence changes
   or new topics at close; they never apply them silently.
5. **Never write DECISIONS.md** (rule 4). If a lesson surfaces a decision, propose text
   for the owner to paste, as with any capture.
6. **Never detect human qualities** (rule 5). Do not assess the owner's intelligence,
   aptitude, diligence, or potential. Grade the *answer*, not the *person*.

The goal is never "the owner can recite the fact." The goal is **understanding**: the
fact is derivable from foundations already held, connected into the mental model, and
therefore self-preserving.

---

## The Philosophy (why the method works)

Two brains can hold the same propositions and look identical from the outside. One
holds a pile of **disconnected lone facts**; the other holds a few **core truths** from
which the facts are derivable, so the facts are visibly connected. That connection *is*
understanding.

- Connected knowledge > disconnected knowledge
- A graph of dependencies > disjoint lonely nodes
- Understanding > memorising

Understanding preserves knowledge (held in place by its connections), compresses it,
and is better. Every teaching move builds that dependency graph in the owner's head:
**nodes** (Principle i) and **edges** (Principle ii).

**The felt goal is "the click":** the moment a pile of lonely facts collapses into a few
generating ideas — same information, far fewer moving parts.

A key mechanism: **the brain will not fully commit to a fact it is not sure is safe to
lock in.** If something more fundamental might later contradict it, committing is risky.
Both principles remove that risk.

**This is why teaching from KBS is stronger than teaching from a bare vault:** the wiki
already holds the dependency graph (typed relationships) and the safety metadata
(confidence + conditions) that this method depends on.

---

## Principle i — Unconditional truths first

Start from the ground. Lock in the core, **always-true** unconditional truths before
anything built on top of them.

Why here? **Not** because bottom-up is logically "correct" — because unconditional
truths are the *easiest* thing for the brain to accept and lock in. They are safe, so
they commit instantly, and they give the first solid ground to build from.

**Terminology — keep these distinct; do not overuse "axiom."** An *unconditional truth*
is a fact the owner can accept **as-is, at face value, with no caveats** — a property of
*how the fact is held*. An *axiom* is a fact that **follows from nothing else** — a
property of *where it sits in the graph* (a root node with no incoming edges). They
overlap but are not synonyms. Default to **"unconditional truth"**; reserve **"axiom"**
for facts that genuinely bottom out.

- Find the few hard facts that can be taken at face value.
- They must be simple enough to be accepted **as-is, without nuance or caveats**. If it
  needs conditions, it is not an unconditional truth yet — dig down further.
- They can be committed to *instantly and safely*. That safety is what makes them lock in.
- Build everything else up from these, explicitly.

**Confirm the foundation before building on it.** Briefly check that each core truth
reads as obviously true to the owner before adding structure. If it does not feel
rock-solid, stop and fix the foundation — do not build on sand.

**Two strong forms to reach for:**
- **Universal statements** — *"all X are Y"*. A clean atomic-unit version
  (*"ALL X is done through {____}"*) is one strong special case.
- **Real definitions** — only if it is an *actual* definition, not a vague list of
  properties dressed up as one.

Do not force either where there is not a clean one.

---

## Principle ii — "How could I have discovered this?"

Facts feel arbitrary when there is no visible reason they *had* to be this way. The
brain will not commit to arbitrary-feeling info. The fix: make it feel discovered, not
decreed. Walk the owner through how they **could have discovered it themselves**. Every
step must be *motivated*:

- Start from square one: **why are we even doing this?**
- Motivate every intermediate step: why try *this* formula? why manipulate *this* way?
- The output turns **disconnected propositions → connected propositions** — adding edges.

3Blue1Brown (Grant Sanderson) is the reference standard: nothing appears from nowhere.

### Socratic vs expository — adaptive

- **Socratic** — pose the motivating problem and let the owner attempt discovery first.
  More effortful, stronger locking-in. Default when they can plausibly reason it out.
  "Let them attempt it" is about *who speaks first*, not grading: if the question has a
  definite right answer, it is still gradable — use `quiz`. Reserve
  `ask_user_question` for genuine no-right-answer forks (preferences, direction).
- **Expository** — narrate the motivated discovery path yourself (3B1B style). Use when
  the topic is beyond cold-reasoning reach, or the owner is low-energy.

When unsure, lean Socratic for things that are clearly reasonable; otherwise narrate.

---

## The Process: probe → plan → teach

The principles are *how*. This is *when*. Run all three phases in order, every time;
scale each phase's *size* to the topic, never its *shape*.

### Phase 1 — Probe (never skip)

**1a. Current level — use `quiz`. A mapping job, not a spot-check.** Locate the *edge*
of understanding — the frontier where what is reliably known turns into what is not —
along every strand the lesson will depend on.

**The edge is only located when it is bracketed.** For each relevant strand you need
*both* something the owner gets **right** (a floor) and something they get **wrong**
(a ceiling). The edge sits between them.

- **All-correct means the questions were too easy.** Escalate sharply until something
  breaks. If nothing ever breaks, you never found the edge.
- **Binary-search the edge.** On a correct answer, jump difficulty up *sharply*. On a
  miss, narrow back in.
- **One wrong answer is not "done."** Probe *around* it to characterise it: careless
  slip, isolated gap, or systematic misconception. Misconceptions must be dislodged.
- **Map every strand the lesson rests on.** Bound by relevance to the goal.

Do not advance until, for each goal-relevant strand, you can state both what is held and
where it ends.

**1b. Learning goal — use `ask_user_question`.** Find out what the owner actually wants
taught. With an unfamiliar subject the goal is often hard to articulate — "understand
LLMs" can mean ten different things. Interrogate until concrete. No right answer, so
`ask_user_question`, never `quiz`.

### Phase 2 — Plan (think hard; highest-leverage step)

**Scope with the wiki first — always.** Run the **Query process**
(`reference/ingestion.md` §Query, agents.md §Query Process) on the topic. Read
`wiki/topics/INDEX.md`, traverse typed relationships, and pull the claims, confidence
levels, and conditions that already exist.

Then branch on what the wiki holds:

**If the wiki covers the topic** — plan from those claims. This is the primary source in
*both* modes.

**If the wiki does not cover the topic (or covers only a fragment):**

- **Wiki-only mode (default): stop and refuse.** Do not teach the topic. Instead:
  1. Capture a Question to `INBOX §Open Questions`: *"Teach '[topic]' — no wiki basis"*.
  2. Tell the owner plainly: *"'[topic]' isn't grounded in the wiki yet. I can't teach it
     from nothing. Either ingest a source on it first, or re-run with `— from sources`,
     which researches it and captures everything I assert."*
  3. End the lesson. A refusal is a correct outcome, not a failure.
- **Bootstrap mode (`— from sources`):** research the gaps externally, but **every
  externally-sourced claim must be captured before or while it is asserted** (see
  §Mandatory Capture in Bootstrap Mode). Mark its provenance visibly in the lesson:
  e.g. `[external — ungrounded, captured as [[topic]]]`.

Never fall back to external research in wiki-only mode. Never re-derive what is already
grounded in the wiki in either mode.

Then plan against the philosophy:

- Which wiki claims are HIGH **and** condition-free? Those are candidate unconditional
  truths. Which are conditioned/MEDIUM/LOW, and therefore need the motivated path?
- Which foundations does the owner already hold (from Phase 1a)? Build from there.
- What is the motivated discovery path to the goal? Where does each step come from?
- Socratic or expository for each stretch?

**Present the plan in chat — always, before teaching.** Two parts:

1. **The approach, in prose** — what we will cover, in what order, and why, given the
   edge (1a) and the goal (1b).
2. **The dependency map** — the plan's backbone as a DAG: unconditional truths at the
   roots, each derived node hanging off its dependencies, the goal as the sink. Draw it
   as a small mermaid graph **and** as KBS typed relationships (`Causes` / `Leads To` /
   `Depends On`) where they are claimable. Keep it small: a map, not the territory.

**Stress-test the roots before presenting.** For every node treated as foundational, ask:
is this genuinely an unconditional truth *for the owner*, or a disguised theorem that
derives from something simpler? If it derives, push it down. A wrong root corrupts
everything hung off it.

**Then stop and wait for the go-ahead.** The plan is the checkpoint. Do not begin Phase 3
until the owner okays it.

### Phase 3 — Teach (the loop)

Build the dependency graph one **node** at a time. For **every node** (each unconditional
truth *and* each non-trivial derived step):

1. **Motivate.** Why do we need this node *now* — what problem does it solve? This applies
   to unconditional truths too: do not assert one merely because it is true.
2. **Establish.**
   - Foundational unconditional truth (HIGH + condition-free): state it plainly, at face
     value, no caveats.
   - Derived step: build it from what is established via a motivated move (Socratic or
     expository). When a Socratic step has a gradable answer, pose it with `quiz`.
3. **Connect.** Make the dependency edge explicit — show how this node hangs off the ones
   in place, so it is understood, not memorised. Cite the wiki topic and confidence.
4. **Quiz-check.** Confirm the node landed with a quick `quiz` — foundations included. An
   unconfirmed foundation is as dangerous as an unconfirmed derived fact.

Repeat the full loop per node. Any time a new unconditional truth is needed mid-session,
it goes through motivate → establish → connect → quiz-check.

If you catch yourself asserting a fact the owner would have to take on faith, stop:
either motivate it and confirm it lands, or ground it in something already established.

---

## Writing Quiz Options — A Construction Procedure

Applies to every `quiz`. The tool asks for even options, but that is a *post-hoc audit*.
Build the options so evenness is automatic:

1. **Every option is a bare claim — no justification anywhere.** The number-one giveaway
   is the correct option carrying its own reasoning while distractors are bare, making it
   longer and more specific. Put *zero* "why" in any option; all reasoning goes in the
   `explanation` field, shown only after answering.
2. **Write the correct claim first, then mutate it into each distractor.** Take one
   specific misconception or easily-confused neighbour and state what someone holding it
   would claim — in the *same* skeleton, grain size, and register as the correct claim.
3. Each distractor must be a real error the owner might actually make (so the choice is
   diagnostic), yet unambiguously wrong on the intended reading.
4. **No asymmetric bolding.** Do not bold the tested term only in the correct option.

If, reading the finished set cold, you can still tell which is right without knowing the
material, you skipped step 1 or 2 — regenerate, do not patch.

---

## Capturing Back Into KBS (the loop closes)

A lesson that teaches but captures nothing is a session without learning. At the end of
the lesson (and whenever a natural capture point arises), route outcomes into KBS using
the existing capture path (`kbs_capture` tool, or an INBOX entry). **Capture; do not
ingest.** The librarian processes these later, under the normal pipeline.

| What the lesson produced | Where it goes | Pattern |
|---|---|---|
| A genuine gap — something the owner cannot yet do | `INBOX §Open Questions` | Question |
| A misconception the quiz exposed | `INBOX` (contradiction / Learning Trigger) | Confusion |
| A fact that finally "clicked", with evidence it landed | `INBOX` → `SUCCESSES.md` stub on ingest | Solution (+ conditions/evidence) |
| A claim the lesson showed to be shaky or wrong | Flag for confidence review (proposal only) | Confusion / Failure |
| A new topic the lesson surfaced but the wiki lacks | `INBOX` → wiki stub on ingest | Question / Idea |
| A decision the owner reached mid-lesson | Propose text for `DECISIONS.md` (owner pastes) | Decision |
| **An externally-sourced claim asserted in bootstrap mode** | `INBOX` with its source URL, **before it is taught** | Solution / Question (LOW) |

Rules for capture:

- **Attribute and timestamp** every captured entry (LLM + date), confidence LOW by
  default, as with chat insights (rule 8).
- **Quiz outcomes propose, they do not apply.** A repeated miss is a *failure with data*
  and a diagnosed fact is a *success* — but confidence movement requires approval
  (rule 2). Write the proposal; the owner approves at close.
- **Never write wiki claims directly.** New claims go to INBOX and travel the pipeline.
- **Never write DECISIONS.md.** Propose; the owner pastes (rule 4).

The lesson artifact itself is an output: write it to
`outputs/YYYY-MM-DD-lesson-[slug].md` (query outputs already live in `outputs/`),
including the approach, the dependency map, and the quiz trail.

### Mandatory Capture in Bootstrap Mode

Bootstrap mode's licence to teach beyond the wiki is **paid for by capture**. Every
claim the tutor asserts that is *not* grounded in the wiki must be written to INBOX —
with its source URL and LOW confidence — **before or at the moment it is asserted**,
never deferred to the end (a deferral risks the lesson ending early and the claim
vanishing).

- Attribute as a chat insight: `(LLM + date)` and the source URL (rule 8).
- Mark provenance inline in the lesson so the owner always knows which statements are
  grounded and which are borrowed: `[external — ungrounded, captured as [[topic]]]`.
- If a claim cannot be sourced, do not assert it. An unsourceable claim is not taught,
  in either mode.
- The lesson report must list every externally-sourced claim it captured.

---

## Session Close Integration

A lesson run as part of a session is closed by the normal session close. In addition:

- The captured gaps and misconceptions from the lesson appear in the close's
  **Open Questions** and **Failures/Confusion** steps.
- **Propose** any confidence changes the lesson justifies (e.g. a topic the owner
  demonstrably now understands → proposal to upgrade; a claim the lesson contradicted →
  proposal to review). Do not apply them.
- A lesson is a **learning win** and may supply the close's required CAREER.md
  achievement (step 8) when the owner wants it recorded.

---

## Boundaries (Learning-Specific)

- **Passive.** Never start a lesson without `Teach me [KB]:`.
- **Mode is explicit, never inferred.** No `— from sources` in the prompt → wiki-only.
- **Wiki-only refuses unknown topics.** If the wiki does not ground the topic, capture a
  Question and stop; do not teach from the web. Bootstrap mode is the only way to teach
  an ungrounded topic, and it requires capture.
- **Bootstrap asserts nothing it did not capture.** Every externally-sourced claim is
  written to INBOX with a source URL (LOW, rule 8) before it is taught.
- **Verify, never wing it.** Check the wiki before stating any claim.
- **Confidence ≠ unconditional-truth.** Only HIGH + condition-free claims are presented
  as caveat-free truths.
- **Capture, do not ingest.** New knowledge enters via INBOX and travels the pipeline.
- **Propose, do not apply.** Confidence changes and decisions are proposals (rules 2, 4).
- **Grade answers, never people** (rule 5).
- **Proofread nothing into the wiki directly.** The librarian proposes and routes; the
  tutor teaches and captures.

---

## Report Format

```
LESSON REPORT — YYYY-MM-DD
Topic: [topic]
KB: [name]
Mode: Wiki-only | Bootstrap (from sources)

### Wiki Coverage (Phase 2)
- Grounded in: [[topic1]], [[topic2]] — or "NOT COVERED — refused" (wiki-only)

### Edge Found (Phase 1)
- [strand] — floor: [what was held] / ceiling: [where it ran out]

### Plan (Phase 2)
- Roots (unconditional truths): [list — note HIGH + condition-free vs motivated]
- Path to goal: [summary]
- Mermaid dependency map: [in lesson output file]

### Taught (Phase 3)
- Nodes taught: [n]
- Quiz checks: [n] (passed: n / missed: n)

### Captured Back to KBS
- Open questions: [n] — [list]
- Confusions / misconceptions: [n] — [list]
- Solution stubs (clicked): [n] — [list]
- Decision proposals: [n] — [list]
- External claims captured (bootstrap only): [n] — [claim → source URL]

### Confidence Changes Proposed (owner approves)
- [[topic]] MEDIUM → HIGH — [evidence from lesson]
- [[topic]] HIGH → review — [contradiction found]

### Lesson Output
- outputs/YYYY-MM-DD-lesson-[slug].md
```
