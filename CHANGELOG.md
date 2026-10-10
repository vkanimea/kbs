# KBS Changelog

## V0.118 — Pre-backup system-file sync
- **scripts/nightly-backup.sh** — runs a best-effort `kbs-sync.sh` step ahead of `git add -A`, so the data repo is always committed at the current system version ("fix upstream, sync down"). Without it, system-file drift lands as a data-repo commit. Sync failure is non-fatal (the data commit still proceeds) but is logged; opt out with `KBS_PREBACKUP_SYNC=0`. Resolves the deferred action of 2026-10-01, now that the off-host store is in service.

## V0.117 — Learning Operations (Teach me [KB])
- **templates/reference/learning.md** — **new operation.** `Teach me [KB]: [topic]` turns the library back into a tutor. Three fixed phases (probe → plan → teach): Phase 1 maps the *edge* of the owner's understanding with `quiz` (escalate until something breaks; all-correct means the questions were too easy) and finds the goal with `ask_user_question` (no right answer → never `quiz`); Phase 2 scopes the topic with the **existing Query process against the wiki** — replacing the upstream `learn` package's web-research step — and presents a dependency map (mermaid + typed relationships) for approval; Phase 3 builds the graph node by node (motivate → establish → connect → quiz-check). Adapted from amosblomqvist/learn's `teach` skill, with two KBS-critical corrections: **wiki-first verification** (never wing it from memory) and the rule that **wiki confidence ≠ unconditional truth** — only a HIGH-confidence *and* condition-free claim may be presented caveat-free. The operation **reads** the wiki and **captures** outcomes back to INBOX (gaps → Question, misconceptions → Confusion, clicked facts → Solution stub); it never writes claims or confidence directly (rules 1, 2, 4, 5)
- **templates/reference/learning.md — two modes (Option C).** The operation is **wiki-only by default**: a topic the wiki does not ground is **refused**, captured as an open question, and never taught from the web. The explicit override `Teach me [KB]: [topic] — from sources` (bootstrap mode) permits external research but **requires every asserted claim to be captured to INBOX with its source URL and LOW confidence before it is taught** (rule 8), with provenance marked inline. Mode is chosen by the owner, never inferred — this resolves the rule-6/rule-8 tension in teaching beyond the library
- **templates/SYSTEM.md** — **new registered custom style `Learn/Lesson`.** Style Registry now defines what a lesson capture looks like (lesson headers, a dependency DAG, quiz/probe outcomes, a Captured-Back / Confidence-Changes block) and how it is processed: extract the 8 patterns from the capture, preserve the HIGH+condition-free vs conditioned/motivated distinction, keep confidence changes as proposals. Demonstrates the registry as the system's extension point. Frontmatter valid-values list now includes `learn`. Three new **Learning Triggers** (lesson captured but not ingested, misconception exposed by a quiz, lesson-proposed confidence change unapproved)
- **templates/agents.md** — new `Teach me [KB]: [topic]` row in the Operations table; new **Learning Operations** section (5-step summary); boundaries updated (outputs include lesson artifacts; teaching never writes claims); new golden rule: *teaching reads the wiki and captures back to INBOX — it never writes claims directly*
- **templates/PROMPTS.md** — `Teach me [KB]: [topic]` added to Daily and On Demand tables, plus a dedicated **Learning (Teach)** section with variants (expository, known-baseline, focus-on-weak-areas)
- **docs/input-output-guide.md** — new **Style 6 — Learn/Lesson** section; input→output map and one-page summary updated
- **docs/user-guide.md** — new **Learning from the Wiki (Teach)** section; troubleshooting rows for persistent lesson gaps
- **docs/architecture.md** — File Responsibilities (Learning) and Mental Model (`reference/learning.md`; outputs now include lesson artifacts) updated; note that the tutor is a **reader** of the library, keeping a single writer authority over the wiki
- **docs/version-advising.md** — new step 2b: **custom styles must be registered by hand in an existing instance.** `SYSTEM.md` is user-owned and never synced, so the `Learn/Lesson` registry block reaches fresh installs only; existing instances paste it into their own `SYSTEM.md §Style Registry`. The operation file itself (`reference/learning.md`) *is* synced normally
- **⚠️ Existing-instance migration:** after syncing V0.117, add the `Learn/Lesson` style block (from `templates/SYSTEM.md`) to your instance's `SYSTEM.md §Style Registry` — otherwise `Teach me` runs but lesson captures won't auto-detect. Verify with `grep -n "Learn/Lesson" SYSTEM.md`
- **scripts/kbs-sync.sh / install.sh / install.ps1** — `reference/learning.md` added to the sync manifest and both installers
- **scripts/youtube-ingest.sh** — **captions first.** Now tries `yt-dlp` captions (manual English preferred, auto-generated fallback) and strips VTT to plain text *before* falling back to Whisper/whisper.cpp. Videos with captions no longer pay the transcription cost. Header updated to match
- **templates/reference/writing-style.md** — **new reference.** A prose guide for generated content (wiki topics, lesson outputs, query syntheses), adapted from the `stop-slop` skill. Eight rules plus pre-flight checks; explicitly scoped so it never overrides the confidence/conditions rules. Pointer added in agents.md §Wiki Page Format
- **templates/reference/session-analysis.md** — **new operation** `Analyze sessions for [KB]`: reads your agent history (`~/.pi/agent/sessions/`, read-only) for cost, error-heavy sessions, and repeated prompts, then captures findings to INBOX. Repeated corrections → proposals to sharpen system rules; recurring complaints → open questions; now-smooth workflows → Solution stubs. Ported from amosblomqvist/pi-config's `analyze-sessions` skill (stdlib Python, no deps) into `scripts/analyze-sessions/`
- **scripts/analyze-sessions/** — `sessions.py` (shared lib), `cost.py`, `prompts.py`, `search.py`, `show_session.py`, `README.md`. Cost reads the `usage.cost` already in every assistant message; subagent transcripts included by default. System-owned, synced, read-only
- **templates/SYSTEM.md** — new registered custom style `Session Analysis` (the meta loop: repeated corrections and recurring errors flow through the same INBOX pipeline), plus two learning triggers (recurring prompt correction, repeated session error pattern)
- **templates/agents.md** — `Analyze sessions for [KB]` operation row + Session Analysis section; **templates/PROMPTS.md** — Session Analysis prompt group
- **docs/architecture.md** — Tooling Ecosystem + File Responsibilities updated; **docs/user-guide.md** — "Learning from Your Own Sessions" section + troubleshooting row; **docs/input-output-guide.md** — Style 7 — Session Analysis
- **⚠️ Existing-instance migration (Session Analysis):** like Learn/Lesson, the `Session Analysis` style block in `SYSTEM.md` is user-owned and must be pasted by hand; `reference/session-analysis.md` and `scripts/analyze-sessions/` sync normally

### Related pi-config changes (not KBS system files)
- **`web_fetch` extension installed** at `~/.pi/agent/extensions/web-fetch/` (from amosblomqvist/pi-config). Self-contained (`pi` manifest, 4 npm deps). Gives the learning operation's **bootstrap mode** a real retrieval tool (Readability + Turndown; PDFs; Jina Reader fallback). Search uses an OpenRouter `:online` model (existing key, no Google CSE needed)
- **Not adopted:** `bash-guard` — its ideas (subagent hard-block split via `PI_SUBAGENT_DEPTH`, shell-quote parsing) don't beat the existing shared guard (`~/.agents/hooks/dangerous-patterns.txt`, 55 patterns, one file across all agents). Adopting it would fragment the single-source denylist and add complexity with no subagents in use. `web-search` needs a Google CSE key (unavailable). Header/browser/prompt-snippets have no KBS tie
- **README.md** — reference tree updated; **.github/workflows/validate.yml** — **fix: stale reference check.** The CI grepped `templates/reference/session-close.md` for `"10-Step Close"`, but V0.116.4 promoted the close to 11 steps without updating the workflow — the check had silently failed on every run since. Now checks `"11-Step Close"` and adds a `learning.md` presence check (`"Phase 3 — Teach"`)

## V0.116.5 — Reminder Script Correctness (patch)
- **scripts/due-actions.sh** — **fix: false "No overdue actions".** The parser grepped for the bare strings `Done: No` / `Due:`, but entries are written with bold markers (`**Done:** No`). The only literal match was the template prose line above `## Open Actions`, so the script reported 1 open action regardless of how many existed — masking every overdue commitment. The parser now (a) matches the bold marker **lines**, (b) reads Done/Due per entry with a proper flush, so a closed entry no longer leaks its due date into the next one, and (c) treats `**Done:** No` as the sole source of truth rather than gating on section headings — ACTIONS.md carries a stale `## Completed Actions` heading with still-open entries beneath it, so heading gating hid real work. `**Due:**` lines with annotations prefer the **last** date on the line, so `awaiting X (re-dated from YYYY-MM-DD)` uses the live deadline rather than the historical one. Verified against a live instance: 1 reported open action → **15**
- **scripts/health-check.sh** — **fix: shell error `integer expression expected`.** `UNRESOLVED=$(grep -c ... || echo "0")` double-printed the count: `grep -c` already prints `0` *and* exits 1 on no matches, so the fallback appended a second `0` and the variable became `0\n0`, failing the later `[ ... -gt 0 ]` test. The count is now read plainly and coerced to a non-negative integer, and `PENDING` is given the same guard

## V0.116.4 — Drift Guard in the Close Loop (patch)
- **scripts/kbs-drift-check.sh** — daily wrapper around `kbs-sync.sh --check`, scheduled by cron. Logs to `log.md` **only when drift is found** (a healthy instance stays quiet), and sends a desktop notification where available. Skips quietly if the system repo or `kbs-sync.sh` is unavailable, so cron never mails spuriously
- **templates/reference/session-close.md** — the close is now **11 steps**: step 11 checks system-file drift after any session that touched `scripts/`, `docs/`, `templates/`, `agents.md`, `PROMPTS.md`, or `reference/`. A fix made only in an instance is a fork; reconcile or promote upstream before closing
- **templates/agents.md** — **fix: CI word-limit breach.** The file had exceeded its 1,200-word limit since V0.114 (1,239 words), failing the `agents.md stays lean` check on every run since. The duplicated style-detection table (already owned by `SYSTEM.md §Style Registry`) and a verbose session-start line were condensed: 1,239 → 1,138 words. No instruction was removed — the table is still in SYSTEM.md, which agents.md directs the session to read
- **install.sh / install.ps1** — install `kbs-drift-check.sh`

## V0.116.3 — System/Data Drift Guard (patch)
- **scripts/kbs-sync.sh** — refreshes a data instance's system files from the system repo, and detects drift with `--check` (non-zero exit when instance system files differ). Modes: `--dry-run` to preview, `--from`/`--to` to override paths. Mirrors `install.sh`'s contract exactly — system files are overwritten, user files (INBOX, CHAT_INBOX, DECISIONS, FAILURES, SUCCESSES, ACTIONS, JOURNAL, CAREER, SYSTEM, `log.md`, `.gitignore`) are never touched
- **docs/architecture.md** — new *System repo vs data repo — one source of truth* section stating the rule: system files are edited upstream, then synced down. A system file fixed only in an instance is a fork
- **docs/version-advising.md** — release step 1 now uses `kbs-sync.sh --check`; drift check added to the verification list
- **install.sh / install.ps1** — install `kbs-sync.sh`; `install.ps1`'s script list brought in line with `install.sh` (it was missing `goal-loop.sh`, `graphify-index.sh`, and the RAG scripts)

## V0.116.2 — Graphify Activation Fixes (patch)
- **scripts/graphify-index.sh** — `--mode` now defaults to `deep` (graphify ≥0.9 rejects `standard`; the old default silently failed to build a graph). The wrapper now passes `--code-only` to graphify when no LLM key is configured, so a code corpus indexes via the deterministic local AST with zero token cost instead of erroring on the semantic-extraction path. Also adds explicit backend selection: `--local` (llama.cpp OpenAI-compatible server), `--openrouter`, and `--backend <name>`, with auto-detection falling back to code-only when no key is present
- **scripts/nightly-backup.sh** — commit-only by default. The data repo targets an external remote, so it always commits locally (nothing is lost) but pushes only when `KBS_ALLOW_EXTERNAL_PUSH=1` is explicitly set. Prevents accidental publication of org-specific knowledge to an external remote

## V0.116.1 — Client-Agnostic Framing (patch)
- **Make LLM-client setup client-agnostic.** Removed the "Claude Desktop (easiest)" headline from the LLM Client Configuration section; replaced with a general requirement (grant folder read/write to `~/kbs`) plus per-client-class examples (chat/desktop, Ollama + Open WebUI, agent harnesses). Claude Desktop now appears only as one item in a multi-client examples list. Not a feature — a wording/plumbing fix, hence a patch
- **`.env` / installer defaults now `LLM_CLIENT=any`** (was `claude`). Informational only — KBS scripts never read it — but the default no longer implies a preferred provider. Applied in `install.sh`, `install.ps1`, `docker/docker-entrypoint.sh`, `.env.template`
- **docs/deployment.md** — generalized the API-keys section (any provider, local models need none) and removed the Claude-only curl example model string
- **install.sh / install.ps1 / INSTALL.md post-install step 1** — wording now "any LLM client works" instead of a Claude Desktop permission path
- README already stated "No LLM lock-in — any LLM" and is left intact; `chat-adapter.sh` already detects Claude/ChatGPT/Gemini/Ollama/Mistral for transcript labels

## V0.116 — Agentic Capabilities (goal-loop + knowledge-graph)
- **scripts/goal-loop.sh** — persistent Ralph//goal loop orchestrator on pi: wraps pi's agent loop, reads a goal contract (objective/read_first/constraints/validate/stop_when/max_iter), runs `pi --print --provider --model`, runs the validate gate via `bash -c`, and feeds failures back each iteration until the gate passes or the budget is exhausted. Provider/model configurable via env (defaults to wired openrouter/deepseek). Exit codes: 0=met, 1=budget exhausted, 2=bad spec, 3=pi couldn't run
- **docs/goal-spec.md** — the goal-contract format (four required parts: objective, constraints, validate, stop-when) plus a field guide and good/bad examples
- **examples/goal** — runnable example goal spec
- **scripts/graphify-index.sh** — per-project knowledge-graph + agent-crawlable wiki indexer using Graphify (deterministic tree-sitter AST; no LLM, no vector store). Outputs to `kb/projects/<project>/graphs/` (graph.json, GRAPH_REPORT.md, graph.html, analysis.json) and `kb/projects/<project>/wiki/graph/` (agent-crawlable markdown + index.md entry point, with `--wiki`). Community naming needs a wired `claude -p` CLI and degrades gracefully to placeholders
- **install.sh — installs the two new scripts** (goal-loop.sh, graphify-index.sh) via the SCRIPTS array

## V0.115 — Git-Remote Backup & Restore
- **scripts/nightly-backup.sh** — commit + push the data repo to its (private) git remote when changed; repo-local credential helper auto-asserted so fresh clones stay push-capable; logs to `backup.log`
- **docs/backup-and-restore.md** — the git-remote backup pattern: private data repo vs public system repo, what a clone restores vs what you rebuild (.env, RAG indexes, cron), restore procedure, operational notes
- deployment.md backup section superseded — tarball copies replaced by the versioned git-remote pattern (see docs/backup-and-restore.md)
- Version strings stamped repo-wide (docs, templates, scripts, installers, Dockerfile) — historical entries in this changelog and README's "What's New" sections intentionally keep their original version
- **Docker: system/data separation** — image carries the system payload (`/opt/kbs-system`); data lives in a host bind mount (`${KBS_HOME:-./kbs}:/root/kbs`); entrypoint refreshes system files and preserves user files. Replaces named volumes (wiki/raw/outputs only), which silently dropped capture files and non-main KBs on rebuild
- **docker/docker-entrypoint.sh** — seed-if-missing for user files, refresh for system files; `tini` as PID 1
- **.dockerignore** — keeps `.git`, `.env`, `kb/`, and the host data dir out of the build context
- **install.sh / install.ps1 — no more data loss on upgrade.** User-owned files (`INBOX.md`, `FAILURES.md`, `SUCCESSES.md`, `ACTIONS.md`, `DECISIONS.md`, `JOURNAL.md`, `CAREER.md`, `CHAT_INBOX.md`, `SYSTEM.md`, `log.md`, `.gitignore`) are now seeded only when missing and **never overwritten**; system files (`agents.md`, `PROMPTS.md`, `reference/`, `scripts/`, `CHANGELOG.md`, `VERSION`) still refresh. Fixes a latent bug where re-running the installer wiped captures and `log.md` history. Installers now report kept files and log `SYSTEM_UPGRADED` on re-run
- **install.sh** — now installs `VERSION` (introspection) and is committed executable (fix: `./install.sh` failed with *Permission denied* on a fresh clone); same fix for `chat-adapter.sh`, `chat-api-adapter.py`, `health-check.sh`, `status.sh`
- **install.sh / install.ps1** — version now read from `VERSION` (banner, `.env.template`, log line) so installers never drift from the release; both install `nightly-backup.sh` + `git-credential-env.sh` (previously missing from fresh installs)
- **VERSION** file added at repo root and in instances
- deployment.md — Docker install now documents the private-data-repo + host-side backup pattern, Docker upgrade path, and the native-upgrade overwrite caution
- **docs/architecture.md — new “The Harness Layer” section**: KBS ships instructions + state, not an agent; distinguishes chat clients (max Activity Level 1) from tool-using agent harnesses (up to Level 3, since they can run scripts/git/schedules); reinforces harness-agnosticism and the CHAT_INBOX transcript-capture path
- **docs/deployment.md** — new “Agent Harnesses” subsection under LLM Client Configuration (what to look for, what it unlocks, capture pattern)

## V0.114 — Semantic Retrieval (RAG alongside)
- **scripts/rag.py** — stdlib-only semantic index/query over `wiki/topics/`, using Ollama embeddings (default `nomic-embed-text`); no pip dependencies
- **scripts/rag-index.sh / rag-query.sh** — thin wrappers; index stored at `kb/<name>/rag-index/index.json` (git-ignored, regenerable)
- **install.sh** — installs the RAG scripts; generated `.gitignore` now excludes `kb/*/rag-index/`
- Retrieval layer remains disposable; markdown + git is the system of record
- **hourly-ingest.sh** — post-ingest step now rebuilds the RAG index automatically (logged as `RAG_INDEX` in log.md); cron entry documented at top of the script
- **docker/docker-compose.yml** — Option A wires host Ollama via `host.docker.internal`; Option B (self-contained ollama sidecar) documented as commented block; RAG defaults overridable via `KBS_RAG_MODEL` env

## V0.114 — Journal Operations & Hourly Automation (former V11.4)
- **Journal** — reflective capture grounded in wiki context, pattern detection across entries
- **Journal operations** in agents.md — save, read context, respond grounded, detect patterns
- **Hourly ingestion script** — `scripts/hourly-ingest.sh` checks raw/ and auto-processes
- **raw/processed/** routing — processed files moved out of raw/ to prevent re-ingestion
- **YouTube ingestion** — `scripts/youtube-ingest.sh` downloads + transcribes + creates INBOX entry
- **YouTube Transcript** custom style in Style Registry

## V11.3 — Style Registry & Input Architecture
- **Input Style Registry** — 5 built-in + extensible custom styles
- **6-step ingestion pipeline** with explicit style detection order
- **Held entry state** — Rapid entries never rejected, expanded at session close
- **Link-richness curve** — typed links depend on pattern completeness
- **Activity Level × Style processing matrix**

## V11.1 — Solution Patterns & Success Learning
- **Solution pattern** with Conditions, Limitations, Evidence
- **SUCCESSES.md** + confidence upgrades
- **ACTIONS.md** commitment tracking
- **8 patterns** formalized
- **Format map** and **root ideas** documented

## V11.0 — Lazy-Loaded Instructions
- `agents.md` cut from ~3,000 to ~800 words
- Operation detail moved to `reference/` modules
- Single-source restructure: SYSTEM.md, PROMPTS.md as canonical
- CI enforces agents.md < 1,200 words

## V10.3 — INBOX Quality Framework
- INBOX entry quality rating: Excellent / Good / Poor / Held
- Quality rejections with rewrite suggestions

## V10.2 — Session Close & Career Portfolio
- Session close command formalized
- **CAREER.md** auto-maintained portfolio

## V10.1 — Failure Learning
- **FAILURES.md** structured failure capture
- Confidence downgrades on disproven claims

## V10 — Universal Chat Adapter
- CHAT_INBOX.md for AI conversation capture
- Chat adapter scripts (bash + Python webhook)

## V9 — Failure Containment & Scope
- HIGH-confidence definition tightened
- Scope boundary rules
- Failure containment with automatic level downgrade

## V8 — Activity Levels
- Levels 0→3 with explicit upgrade criteria
- Graduated autonomy path

## V7 — Interaction Model & Prompts
- Component thresholds
- Human-quality limitations documented

## V6 — Confidence Scoring & Validation
- Confidence levels: LOW / MEDIUM / HIGH
- Evidence-based confidence movement

## V1–V5 — Core Pipeline
- Ingestion pipeline
- Typed relationships (Causes, Leads To, Depends On, CONSTRAINS, Related)
- Wiki topic format
- raw/ → wiki/ → outputs/ flow
