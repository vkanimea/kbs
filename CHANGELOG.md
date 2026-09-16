# KBS Changelog

## V0.115 — Git-Remote Backup & Restore
- **scripts/nightly-backup.sh** — commit + push the data repo to its (private) git remote when changed; repo-local credential helper auto-asserted so fresh clones stay push-capable; logs to `backup.log`
- **docs/backup-and-restore.md** — the git-remote backup pattern: private data repo vs public system repo, what a clone restores vs what you rebuild (.env, RAG indexes, cron), restore procedure, operational notes
- deployment.md backup section superseded — tarball copies replaced by the versioned git-remote pattern (see docs/backup-and-restore.md)
- Version strings stamped repo-wide (docs, templates, scripts, installers, Dockerfile) — historical entries in this changelog and README's "What's New" sections intentionally keep their original version

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
