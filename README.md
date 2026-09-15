# Knowledge Base System (KBS) V0.114

[![Version](https://img.shields.io/badge/version-0.114-blue.svg)](https://github.com/vkanimea/kbs)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)]()

An **agnostic, self-improving second brain** — a governed, evolving knowledge graph that learns from successes *and* failures, compounds every session, and improves not just what it knows, but how it runs.

**Agnostic by design:**
- **No LLM lock-in** — plain-text instructions that any LLM follows: Claude, GPT, Gemini, Ollama, or whatever comes next. Switching providers means zero migration.
- **No app lock-in** — knowledge lives in plain markdown + git, fully yours. Obsidian, Notion, and Logseq are optional read-only viewers, never the system of record.
- **Self-improving** — failure learning, confidence scoring, and session-close compounding; even its own instructions are lazy-loaded and refined, the same way its knowledge is.

Inspired by Andrej Karpathy's "second brain" pattern — minus the dependencies.

---

## What's New in V0.114

V0.114 adds **semantic retrieval (RAG alongside)** — optional fuzzy search over `wiki/topics/`, while markdown + git stays the system of record:

- `scripts/rag.py` — stdlib-only index/query, Ollama embeddings (default `nomic-embed-text`), no pip deps
- `scripts/rag-index.sh` / `rag-query.sh` — thin wrappers; index at `kb/<name>/rag-index/` (git-ignored, regenerable)
- `hourly-ingest.sh` post-step rebuilds the RAG index automatically (logged as `RAG_INDEX`)
- Query procedure now 7 steps — step 0 optional semantic lookup; link rules in `reference/ingestion.md` gained a semantic assist
- Docker compose wires host Ollama (option A) or a self-contained sidecar (option B, commented)
- git credential helper serves `GITHUB_TOKEN` from the git-ignored `.env`

---

## Why This Is Different

| Feature | Traditional Notes | KBS V0.114 |
|---------|-------------------|-----------|
| Linking | Manual | Typed relationships (Causes, Leads To, Depends On) |
| Learning | Success only | Success + failure, with confidence downgrades |
| Automation | None or all | Activity Levels 0→3, trust-gated |
| Career tracking | Manual | Auto-maintained via session close |
| LLM provider | Locked-in | Any: Claude, GPT, Gemini, Ollama |
| Note app | Locked-in | Any — Obsidian/Notion as optional viewers, never the store |
| Self-improvement | None | Core feature — refines its knowledge *and* its own instructions |
| Format | Often proprietary | Plain markdown, git-friendly |

---

## Install

**Linux / macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash
```

**Starter KB (optional)** — copy 20 pre-built example topics to see KBS in action immediately:
```bash
cp -r ~/kbs/examples/starter-kb/wiki/topics/* ~/kbs/kb/main/wiki/topics/
```

**Windows (PowerShell as Administrator)**
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"
```

**Docker**
```bash
git clone https://github.com/vkanimea/kbs.git && cd kbs/docker
docker compose up -d
```

Details and custom paths: [INSTALL.md](INSTALL.md)

---

## How It Works

```
INBOX.md ──► validation ──► wiki/topics/ (typed links) ──► outputs/
   ▲                                                          │
   └────────────── compounding (session close) ◄──────────────┘
```

The structure after install:

```
~/kbs/
├── agents.md            # Core rules (~800 words) — LLM reads every session
├── reference/        # Operation detail — loaded only when needed
│   ├── session-close.md
│   ├── ingestion.md
│   ├── chat-input.md
│   ├── failures.md
│   └── health-check.md
├── SYSTEM.md         # Config: activity levels, scope, metrics targets
├── PROMPTS.md        # All prompts (single source)
├── DECISIONS.md      # Your judgement (LLM never writes here)
├── INBOX.md          # Capture
├── CHAT_INBOX.md     # Chat capture
├── FAILURES.md       # Failure learning
├── CAREER.md         # Auto-maintained portfolio
├── log.md            # Append-only audit trail
└── kb/main/          # raw/ · wiki/topics/ · outputs/
```

---

## The One Command That Matters

```
Follow agents.md. Close session for main
```

Run after every work session. It extracts concepts into wiki pages, documents decisions and failures, updates your career portfolio, and flags open questions for next time. **A session without a close is a session without learning.**

All other prompts: [templates/PROMPTS.md](templates/PROMPTS.md)
Daily/weekly/monthly rituals: [docs/user-guide.md](docs/user-guide.md)

---

## Core Concepts in 30 Seconds

**Activity Levels (0→3):** Start passive — you run every prompt. Earn trust over weeks, then add scheduled proposals (1), routine automation (2), or autonomy (3). Never skip a level. Definitions: SYSTEM.md.

**Typed relationships:** `[[attention-residue]] Causes [[task-switching]]` — links the system can *reason* over, not just navigate.

**Failure learning:** Document failures in FAILURES.md; the system downgrades confidence on disproven claims and detects recurring patterns.

**INBOX quality:** Entries are rated Excellent/Good/Poor at ingestion. Poor entries are rejected with a rewrite suggestion. Quality in = knowledge out.

**Journal:** Reflective writing grounded in your wiki. The LLM reads your accumulated knowledge before responding — not generic advice, but *your* advice, citing what you've saved.

**Starter KB:** 20 pre-built cross-linked topics demonstrate wiki structure, confidence levels, and typed relationships. Copy and explore before writing your own.

**Self-improving system:** The same principles it applies to knowledge — lazy loading, failure learning, compounding — are applied to its own instructions: `agents.md` stays at ~800 words with a CI-enforced bloat guard (<1,200 words); operation detail lives in `reference/` and loads only when an operation runs.

**Local search index:** For 100+ topic KBs, `scripts/topic-index.sh` accelerates topic selection before LLM synthesis.

**Semantic index (RAG):** Optional fuzzy retrieval over `wiki/topics/` — `scripts/rag-index.sh` / `rag-query.sh`, local Ollama embeddings, no pip deps. Index regenerable, built after each `hourly-ingest.sh` run; source of truth stays markdown + git.

---

## Relationship to Note Apps (Obsidian, Notion, Logseq)

KBS is not a note-taking app — and it doesn't need one. The knowledge base is plain markdown at `kb/main/wiki/topics/`. Want a visual graph? Open that folder as a **read-only Obsidian vault** — but never edit there. All writes flow through KBS's governed INBOX pipeline so quality gating, typed links, and the audit trail stay intact. Any viewer that reads markdown works; none of them becomes the system of record.

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/architecture.md](docs/architecture.md) | Full architecture and version history |
| [docs/user-guide.md](docs/user-guide.md) | Daily usage and rituals |
| [docs/deployment.md](docs/deployment.md) | Install options, LLM clients, scheduling, backup |
| [docs/swot-analysis.md](docs/swot-analysis.md) | Honest comparison vs alternatives |

---

## License

MIT — see [LICENSE](LICENSE)
