# KBS Changelog

## V0.116 — Agentic Capabilities (goal-loop + knowledge-graph)
- **Make LLM-client setup client-agnostic.** Removed the "Claude Desktop (easiest)" headline from the LLM Client Configuration section; replaced with a general requirement (grant folder read/write to `~/kbs`) plus per-client-class examples (chat/desktop, Ollama + Open WebUI, agent harnesses). Claude Desktop now appears only as one item in a multi-client examples list
- **`.env` / installer defaults now `LLM_CLIENT=any`** (was `claude`). Informational only — KBS scripts never read it — but the default no longer implies a preferred provider. Applied in `install.sh`, `install.ps1`, `docker/docker-entrypoint.sh`, `.env.template`
- **docs/deployment.md** — generalized the API-keys section (any provider, local models need none) and removed the Claude-only curl example model string
- **install.sh / install.ps1 / INSTALL.md post-install step 1** — wording now "any LLM client works" instead of a Claude Desktop permission path
- README already stated "No LLM lock-in — any LLM" and is left intact; `chat-adapter.sh` already detects Claude/ChatGPT/Gemini/Ollama/Mistral for transcript labels
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
