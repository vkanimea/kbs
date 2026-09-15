# Knowledge Base System (KBS) V11.3

[![Version](https://img.shields.io/badge/version-11.0-blue.svg)](https://github.com/vkanimea/kbs)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)]()

A **governed, evolving knowledge graph with controllable autonomy** — plain-markdown knowledge that learns from successes *and* failures, compounds every session, and auto-maintains your career portfolio. Works with any LLM.

Inspired by Andrej Karpathy's "second brain" pattern.

---

## What's New in V11.3

V11 restructures the system around **lazy-loaded instructions** — the same principle the system applies to knowledge, now applied to itself:

- `agents.md` cut from ~3,000 to ~800 words — the LLM holds only the core rules in context
- Operation detail moved to `reference/` modules, loaded **only when that operation runs**
- Single source of truth: activity levels live in SYSTEM.md, prompts in PROMPTS.md — everywhere else links
- All template examples clearly marked `<!-- EXAMPLE — delete -->` with placeholder dates
- Installers fail loudly on incomplete installs (no silent stubs)
- CI checks actually fail the build, including an agents.md bloat guard (<1200 words enforced)

---

## Why This Is Different

| Feature | Traditional Notes | KBS V11.3 |
|---------|-------------------|-----------|
| Linking | Manual | Typed relationships (Causes, Leads To, Depends On) |
| Learning | Success only | Success + failure, with confidence downgrades |
| Automation | None or all | Activity Levels 0→3, trust-gated |
| Career tracking | Manual | Auto-maintained via session close |
| LLM | Locked-in | Any: Claude, GPT, Gemini, Ollama |
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

**Local search index:** For 100+ topic KBs, `scripts/topic-index.sh` accelerates topic selection before LLM synthesis.

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
