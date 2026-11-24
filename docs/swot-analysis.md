# KBS SWOT Analysis

**Reviewed:** 2026-11-23

**Scope:** KBS system repository and its documented core workflow. This is an architecture review, not an independently sourced competitor benchmark. The capability matrix is a feature inventory, not evidence that KBS outperforms other products.

## Strengths

**S1 — Portable data and instructions.** Markdown and Git keep the knowledge readable and migratable without a proprietary storage format. KBS is designed to be model- and client-portable; actual instruction-following varies by model and harness and is not established by CI.

**S2 — Graduated autonomy policy.** Activity Levels 0–3 give users a vocabulary and criteria for increasing autonomy. In the core system these are primarily policy levels; they do not themselves enforce OS, filesystem, network, or credential boundaries. See W8 and implementation item I3.

**S3 — Explicit relationship types.** Causes, Leads To, Depends On, and other typed links give an LLM structure for navigating and synthesising knowledge. Causal conclusions remain model-mediated; the links do not constitute a deterministic inference engine.

**S4 — Structured learning from failures and successes.** FAILURES.md and SUCCESSES.md record outcomes and support proposed confidence changes. Owner review remains important: the system cannot reliably discover every failure or establish that a solution generalises beyond its stated conditions.

**S5 — Session-close workflow.** A single prompt invokes a procedure that can route and compound session knowledge. It is a user-invoked LLM workflow, not an automatic operation performed by `auto-close.sh`.

**S6 — Quality guidance and shape checks.** The ingestion procedure defines quality criteria, and `scripts/kbs-lint.sh` checks deterministic file and field shapes. Semantic quality ratings are still LLM-mediated; the linter does not prove factual correctness or knowledge quality.

**S7 — Modular instructions.** Core rules link to operation-specific reference modules. CI checks that `agents.md` remains below its word limit and that required references exist.

**S8 — Inspectable and versioned data.** Markdown, Git history, logs, and snapshots make changes inspectable. Backup scripts and tests check aspects of off-site durability. A successful backup check does not by itself prove a complete host restore; restore time and completeness should be reported only when measured.

**S9 — Data ownership is separated from system distribution.** The system repo is portable software; each user's knowledge belongs in their own data repo. Cloud-model processing still sends prompt content to the provider; see `docs/security.md`.

## Weaknesses

**W1 — Routine use depends on user follow-through.** Capture, ingestion, session close, and review still require deliberate action. Reminders can reduce missed work but cannot eliminate this dependency.

**W2 — Human capture is still the main failure sensor.** Structured failures and recurrence checks help after an issue is recorded; they cannot guarantee discovery of uncaptured problems or incorrect assumptions.

**W3 — Setup and operating friction.** Folder access, Git, scripts, model wiring, and prompt rituals are more demanding than opening a hosted notes application.

**W4 — No native mobile capture application.** Existing text-editor, Git, webhook, and voice options are workarounds rather than a unified mobile experience.

**W5 — No built-in always-on graph UI.** Graph views require a viewer or an on-demand graph-generation tool. An external Markdown viewer can help, but is not the system of record.

**W6 — External corpus sync is point-in-time.** A source corpus changing upstream is not automatically reconciled with the ingested KB. O9 addresses incremental source tracking; this is separate from the raw-file lifecycle issue in W7.

**W7 — Raw files can be labelled processed before LLM ingestion.** `scripts/hourly-ingest.sh` scans top-level `raw/` files and moves them to `raw/processed/`. Its own comments say actual ingestion requires an LLM call and is separate. It does not check for an INBOX reference or wait for a successful ingestion result. This conflicts with `templates/reference/ingestion.md`, which says unreferenced files are invisible/orphaned and routes completed entries through the KBS pipeline. A moved file can therefore appear complete without its knowledge having been ingested.

**W8 — Activity levels are not technical containment by themselves.** The core instructions describe what an agent should do. A harness with broader host permissions may still be able to exceed those instructions, especially while processing untrusted content or running a goal loop.

**W9 — LLM behavior has no published evaluation baseline.** CI validates deterministic behavior, installation, file shapes, and wiring. It does not measure how well different model/harness combinations follow the semantic procedures.

**W10 — Documentation and implementation claims can drift.** At review time the README still labels its latest changes as V0.126 while `VERSION` is 0.128.3. Some descriptions of “automatic” behavior and SWOT comparisons also need clearer evidence and qualification.

## Opportunities

| # | Opportunity | Status / effort | Value |
|---|---|---|---|
| O1 | Obsidian-as-viewer guide | Shipped | Optional graph and backlink browsing |
| O2 | Browser extension for one-click chat/article capture | Proposed; medium | Reduces capture friction |
| O3 | VS Code capture/close integration | Proposed; medium | Improves developer workflow |
| O4 | Voice-to-INBOX pipeline | Proposed; low-medium | Faster hands-free capture |
| O5 | Semantic retrieval | Shipped: `scripts/rag-index.sh` and `scripts/rag-query.sh` | Helps KBs where keyword retrieval is insufficient; quality still needs measurement |
| O6 | Starter KB / domain templates | Starter KB shipped; community library proposed | Easier onboarding |
| O7 | Enterprise source integration | Proposed; high | Useful for selected organisations; scope and data boundaries need design |
| O8 | Mobile capture app or PWA | Proposed; high | Addresses the largest capture-surface gap |
| O9 | Incremental external-corpus sync | Proposed; medium | Detects added/changed/removed upstream documents |
| O10 | Safe raw-file ingestion lifecycle | Proposed; medium | Prevents false completion, lost queue visibility, and duplicate processing |
| O11 | Technical enforcement for autonomy boundaries | Proposed; harness-specific | Reduces prompt-injection and credential blast radius |
| O12 | Model/harness behavior evaluation | Proposed; medium | Establishes practical compatibility evidence |
| O13 | End-to-end lifecycle and restore tests | Proposed; medium | Tests workflows beyond isolated checkers and install wiring |

## Threats

**T1 — Prompt injection in untrusted inputs.** Documents, transcripts, and web content can contain instructions that conflict with KBS policy. Risk grows when an agent also has shell, Git, network, or credentials.

**T2 — Model or provider behavior changes.** A model update can alter extraction, confidence, citation, or approval behavior without failing deterministic CI.

**T3 — False confidence from green tests.** Passing shape, wiring, and script tests does not prove factual correctness, high-quality synthesis, or safe LLM behavior.

**T4 — Privacy and credential exposure.** Cloud processing sends content to a provider; broad credentials or accidental pushes can expose more. The private-repo design does not remove these risks.

**T5 — Abandonment and quality decay.** If capture, review, or pruning stops, the KB can become stale or incomplete regardless of its architecture.

**T6 — Complexity and unsupported comparisons.** A large workflow can make onboarding harder. Unmeasured claims of superiority can also erode trust; comparisons should be sourced or presented as design hypotheses.

## Capability Inventory (not a comparative benchmark)

| Capability | KBS status / qualification |
|---|---|
| Activity Levels | Defined as a graduated policy; host enforcement is external/harness-specific |
| Failure and success learning | Structured capture and proposed confidence changes; human review remains important |
| Typed relationships | Stored as explicit links; synthesis and causal interpretation are model-mediated |
| Session close | Prompt-driven workflow; `auto-close.sh` is a report/nudge, not an LLM close runner |
| Quality gate | Semantic rating is model-mediated; linter checks deterministic shape |
| Model portability | Designed for portability; no published model × harness pass-rate matrix |
| Hourly raw-file handling | Current script moves files; it does not perform or verify LLM ingestion |
| Semantic retrieval | Optional local RAG scripts; retrieval quality should be evaluated on representative queries |
| Off-site backup | Git-remote workflow and verification scripts exist; test a fresh restore to establish restore claims |
| Mobile application | Not included |

## Implementation Readiness Plan

**Status: proposed backlog only. No implementation is implied by this plan.** The changes belong in the system repo unless marked harness/instance-specific. Before implementation, preserve unrelated working-tree changes and work from the system repo's source files; sync system changes down to data instances only through the documented KBS sync workflow.

### I1 — Correct documentation to match behavior

**Goal:** Make implemented behavior, model-mediated procedure, policy, and proposed capability distinguishable.

**Primary files:** `README.md`, `docs/architecture.md`, `docs/deployment.md`, `docs/security.md`, `docs/glossary.md`, `docs/swot-analysis.md`, and where relevant `templates/reference/ingestion.md`.

**Procedure:**
1. Confirm each claim against the implementation or procedure it describes.
2. Replace the stale README “What’s New in V0.126” callout with a release-safe heading or a current value derived from the release process.
3. Describe `auto-close.sh` as a status/nudge helper; describe session close as user-invoked unless a separately implemented LLM runner exists.
4. Describe `hourly-ingest.sh` according to the selected behavior in I2; do not call files LLM-ingested unless success is verified.
5. Describe Activity Levels as policy unless an external technical control enforces them.
6. Qualify SWOT superlatives and comparisons; cite evidence or mark them as design intent.

**Acceptance:** The README, architecture, deployment, security, and scripts no longer make conflicting claims about automatic close, hourly ingestion, or enforced autonomy. The SWOT distinguishes observed evidence from hypotheses.

**Verification:** Run `bash scripts/check-doc-versions.sh`, `git diff --check`, and `bash tests/test-wiring.sh <test-instance>`; inspect all modified claims against the referenced scripts/templates.

### I2 — Define and implement a safe raw-file lifecycle

**Decision required before coding:** Choose either (A) a staging-only workflow, recommended for model-agnostic behavior, or (B) a supported LLM adapter that performs ingestion and can verify success. Do not silently treat the current move-to-processed behavior as either choice.

**Primary files:** `scripts/hourly-ingest.sh`, `templates/reference/ingestion.md`, `docs/architecture.md`, `docs/user-guide.md`, plus a new `tests/test-hourly-ingest.sh` and the CI workflow.

**Recommended staging-only procedure:**
1. Define the contract for an eligible file: supported extension, valid KB path, and an INBOX reference as required by the ingestion procedure.
2. Keep original raw content available until an ingestion result is confirmed. A scan or move is not success.
3. Track a stable file identity and explicit states such as `pending`, `processing`, `succeeded`, and `failed`; make repeated hourly runs idempotent.
4. Report orphaned/unreferenced files rather than marking them processed.
5. On failure, retain the source and expose a retryable error. On success, record the result only after the pipeline's expected report/checks are present.
6. Rebuild RAG only when relevant wiki content has changed, and report indexing failure separately from ingestion outcome.
7. If an LLM adapter is later selected, specify supported CLI/API, output contract, timeout, error handling, and how success is verified before enabling it.

**Acceptance:** A file cannot reach `succeeded` merely because it was discovered or moved. Failure and retry preserve the source; repeated runs do not duplicate work; changed content can be reconsidered; paths with spaces are handled.

### I3 — Define and enforce autonomy boundaries

**Decision required before implementation:** Select the harness and deployment environment. Enforcement is harness/instance-specific; do not pretend a generic prompt change enforces host permissions.

**Primary files:** `docs/security.md` and `docs/deployment.md` for portable requirements. Harness-specific configuration belongs in that instance's private configuration unless it is genuinely portable.

**Procedure:**
1. For each Activity Level, document intended actions separately from actual technical permissions.
2. Identify the files, scripts, credentials, and network destinations required for each workflow.
3. Apply least privilege using the selected harness/host controls (for example, sandbox, restricted account, filesystem allowlist, command allowlist, and constrained network access).
4. Keep backup credentials out of untrusted-content processing; use narrow credentials and a separate backup path where feasible.
5. Test allowed and prohibited actions, including prompt-injection content and goal-loop behavior.

**Acceptance:** Documentation identifies which boundaries KBS enforces and which are external. The chosen harness has demonstrated that prohibited filesystem, shell, network, and credential actions are actually blocked.

### I4 — Establish a practical model/harness evaluation

**Primary files:** a new `tests/evals/` fixture and rubric, plus a short README or developer-doc pointer. Do not put private user data or secrets in public test fixtures.

**Procedure:**
1. Create 10–20 sanitized tasks covering normal ingestion, ambiguity, missing evidence, unsupported claims, citation, approval boundaries, and prompt injection.
2. Define observable expected outcomes and a scoring rubric before running models.
3. Run the incumbent model and one alternative with fixed prompts, harness, and level; record model/version, date, harness, and results.
4. Separate mechanically checkable requirements from human quality judgments.
5. Treat results as evidence for tested configurations, not proof that all models are equivalent. Keep paid/live-model runs opt-in; do not send private KB content.

**Acceptance:** Another maintainer can reproduce the evaluation and see pass/fail evidence for each case. KBS claims remain limited to configurations actually tested.

### I5 — Add lifecycle and recovery regression tests

**Primary files:** `tests/test-hourly-ingest.sh`, `tests/test-backup-verify.sh` or a new restore test, and `.github/workflows/validate.yml`.

**Procedure:**
1. Use temporary KB directories and a stub processor; deterministic CI must not require a live LLM or external model API.
2. Test referenced and unreferenced files, success, failure, retry, idempotency, changed content, and filenames with spaces.
3. Exercise the deterministic capture-to-ingestion-result path and run `kbs-lint.sh` on generated owner-data files.
4. In a throwaway repository/remote, back up, clone into a fresh directory, verify expected content, and run restore checks such as `doctor.sh`, `kbs-lint.sh`, and `status.sh` where applicable.
5. Wire the tests into Linux CI. Keep real-model behavior evaluation separate and opt-in.

**Acceptance:** CI fails if a failed ingestion is reported as complete, a retry loses source data, duplicate processing creates duplicate results, or a fresh clone lacks required restore content.

## Assessment

KBS has a well-developed Markdown-first governance design and real operational use. The documented 89-report corpus demonstrates that the workflow has been exercised; it does not, by itself, establish comparative superiority or measured answer quality. The highest-priority gap is the mismatch between raw-file movement and verified LLM ingestion (W7/I2). Next are truthful capability documentation (I1), technical containment for higher autonomy (I3), and evidence from model evaluations and lifecycle tests (I4–I5).

The plan is intentionally not a commitment to implement every opportunity. Before starting I2, choose staging-only versus an LLM adapter. Before I3, name the supported harness and deployment target. Those decisions determine what another implementer can safely build.
