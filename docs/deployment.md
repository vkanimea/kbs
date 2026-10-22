# KBS Deployment Guide

## Install Options

### 1. One-Command (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash          # Linux/macOS
```
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"   # Windows
```

### 2. From Clone (Offline-Capable)
```bash
git clone https://github.com/vkanimea/kbs.git && cd kbs
./install.sh        # templates copied locally — no downloads needed
```

### 3. Docker
```bash
git clone https://github.com/vkanimea/kbs.git && cd kbs/docker
docker compose up -d
docker compose exec kbs bash
```
The compose file ([docker/docker-compose.yml](../docker/docker-compose.yml)) uses the **system/data separation**: the image carries the *system*, and your *data* lives in a host directory bind-mounted at `/root/kbs` (default `<repo>/docker/kbs`; set `KBS_HOME` to move it). Port 8080 is exposed for the chat webhook.

**Make the data directory your private repo** — it is a complete KBS instance, so the backup pattern applies unchanged:
```bash
cd kbs/docker/kbs          # the bind-mounted instance
cp .env.template .env      # add GITHUB_TOKEN
# create a PRIVATE remote, then:
git init && git add -A && git commit -m "KBS data initial"
git remote add origin https://github.com/<you>/<kbs-data>.git
git config credential.helper '!bash scripts/git-credential-env.sh'
git push -u origin master
```
Schedule the host-side backup (runs against the bind mount, no in-container cron needed):
```cron
45 23 * * * cd /path/to/kbs/docker/kbs && ./scripts/nightly-backup.sh >/dev/null 2>&1
```
On every container start the entrypoint **refreshes system files** (`scripts/`, `reference/`, `agents.md`, `PROMPTS.md`, `CHANGELOG.md`, `VERSION`) from the image and **preserves your files** (`INBOX.md`, `FAILURES.md`, `SUCCESSES.md`, `ACTIONS.md`, `DECISIONS.md`, `SYSTEM.md`, `kb/`, `.env`, …) — data is never overwritten.

**The installer aborts loudly on any failed file** — you will never get a silently incomplete install.

---

## LLM Client Configuration

KBS is **client-agnostic** — the interface is markdown + git, and any LLM client that can read/write `~/kbs` works. Examples below cover a representative range; they are options, not requirements.

### General requirement (all clients)
Grant your LLM client folder access to `~/kbs` (read/write). The exact mechanism is client-specific — a permissions dialog, a workspace/folder setting, or a `cd ~/kbs` in a shell-based agent. Then test with the Initial Setup prompt from PROMPTS.md.

### How to wire each client to load `agents.md`

KBS's behaviour lives in `agents.md` (the 11 rules) and the reference files it points to. **If the client never reads `agents.md`, KBS degrades to a plain folder of markdown** — the rules are not enforced, only described. Every client therefore needs a way to put `agents.md` in front of the model. The mechanism differs per client:

| Client | Wiring mechanism | What to do |
|---|---|---|
| **Claude Code** | `CLAUDE.md` project memory | `ln -s ~/kbs/agents.md ~/kbs/CLAUDE.md` (or copy). Claude Code auto-loads `CLAUDE.md` from the working directory each session. Run it with cwd `~/kbs`. |
| **pi** | `AGENTS.md` project file | `ln -s ~/kbs/agents.md ~/kbs/AGENTS.md`. pi loads `AGENTS.md` from the project root at startup. |
| **Aider** | `--read` flag or `.aider.conf.yml` | Add `read: [agents.md, CONVENTIONS.md, SYSTEM.md]` to `~/kbs/.aider.conf.yml`, or pass `aider --read agents.md`. |
| **opencode** | `AGENTS.md` (same convention as pi) | `ln -s ~/kbs/agents.md ~/kbs/AGENTS.md`; open the session with cwd `~/kbs`. |
| **Generic CLI agent** | System prompt / custom instructions | Paste the contents of `agents.md` into the client's persistent-instructions field, or prepend it to the first message. |
| **Chat client (Claude.ai, ChatGPT, Gemini)** | Project / Custom Instructions | Paste `agents.md` into the project's custom instructions. **Level 1 only** — the model can read and propose but cannot run scripts, git, or schedules. |

**The reliable fallback (any client):** begin every session with the literal phrase

> `Follow agents.md.`

`agents.md` is written so this phrase is self-loading — the model reads `agents.md`, which then
points it at `CONVENTIONS.md`, `SYSTEM.md`, and the relevant `reference/*.md` for the operation.
Even clients with a native `AGENTS.md`/`CLAUDE.md` convention should be tested to confirm it fires.

> **Verify the wiring, don't assume it.** A symlink or project file that the client silently
> ignores looks identical to one that works — until the model violates a rule. Use the smoke test
> below to prove the wiring before relying on it.

### 5-minute smoke test (proves the wiring works)

Run this once per client after wiring. It takes ~5 minutes and needs no API key or network.

1. **Open the client with `~/kbs` as the working directory** (or the folder added to its workspace).
2. **Send exactly:**
   ```
   Follow agents.md. Ingest this: "The office coffee machine is on the 3rd floor."
   ```
3. **Expected — the client must:**
   - Read `agents.md`, then `reference/ingestion.md` (it may say so);
   - Write a record to `INBOX.md` (or `kb/main/raw/`), **not** directly to the wiki;
   - Apply a **confidence rating** and a **source attribution** (the chat insight is LOW confidence per Rule 8);
   - Ask before promoting anything to `wiki/` (Rule 2 — propose, don't decide).
4. **Then send:** `Follow agents.md. Close session for main`
   **Expected:** the 11-step close from `reference/session-close.md` runs, and the changes are committed (`git log` shows a new commit).
5. **Pass/fail:**
   - ✅ **Pass** — a new `INBOX.md` entry with a confidence rating + source, and a git commit on close. The wiring works.
   - ❌ **Fail** — the client answered in chat without writing a file, wrote straight to `wiki/`, or skipped the close. The `agents.md` wiring is not firing: fix the mechanism above and retest.

Record the result (client, model, level reached, pass/fail) in your **private data repo**, not in this system.

**Deterministic pre-check.** From a **clone of the system repo** (the `tests/` directory is not
installed into data instances), run:

```bash
bash tests/test-wiring.sh ~/kbs      # point at your instance
```

It verifies the *deterministic half* — that every file `agents.md` says to load actually exists,
and the operation-table references are real. If it passes, any failure in steps 1–4 is a **model**
issue, not a missing-file issue. (It does not prove model behaviour; see README → *Model compatibility*.)

### Chat/desktop clients (Activity Level 1: read & write files)
Examples: Claude Desktop, ChatGPT, Gemini, Open WebUI, or any chat app with folder access. Where your client does not expose a shell, the agent-harness path below is what unlocks automation.

### Ollama + Open WebUI (free, local)
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.3
docker run -d -p 3000:8080 -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```
Open http://localhost:3000 and point the workspace at `~/kbs`. Windows: use WSL2 (`wsl --install`).

### Agent Harnesses (enables levels 2–3)
A chat client can read and write KBS files, but only a **tool-using agent harness** can run the scripts, git operations, and schedules that higher Activity Levels need. Use one when you want routine automation or autonomy.

KBS does not name a preferred harness — which one you run is instance-specific (see [architecture.md](architecture.md) → *The Harness Layer*). Pick from the requirements below.

**Required — without these you are still at Activity Level 1:**

| Capability | Why KBS needs it |
|---|---|
| Shell access | Runs `status.sh`, `rag-index.sh`, `hourly-ingest.sh`, `health-check.sh` |
| File read/write on `~/kbs` | Edits wiki, journals, indexes |
| `git` | Session close, history, backup push |
| Tool-using agent loop | Chains the above without manual copy-paste |

**Optional — each one compounds the loop further:**

| Capability | Value |
|---|---|
| Persists session transcripts | Auto-capture into `kb/<name>/raw/chat-transcripts/` + `CHAT_INBOX.md` |
| Native skills / procedure memory | Stores the close, ingest, and health procedures for reuse |
| Scheduled or headless runs | Unlocks the autonomous Activity Level 3 ceiling |
| Local model support | Works with Ollama/llama.cpp, no provider key needed |

**Choosing one:** use whatever agent your environment already supports — the interface is only markdown + git, so nothing KBS-specific is required. If you have none installed, a shell-capable CLI agent (opencode, pi, Claude Code, or similar) is the lowest-friction start. Document the choice and its configuration in your **private data repo**, not in this system.

**If you pick pi:** `scripts/analyze-sessions/` and `reference/session-analysis.md` work out of the box (they read `~/.pi/agent/sessions`), and the companion exporter pattern (session transcripts → `raw/chat-transcripts/` + `CHAT_INBOX.md`) is documented in *The Harness Layer* in [architecture.md](architecture.md). For any other harness, treat those scripts as a porting template — swap the session-store path and the record schema; the cost/search/render logic is harness-neutral.

**What it unlocks:** `hourly-ingest.sh` scheduling, semantic index rebuilds, session close that commits/pushes (see [backup-and-restore.md](backup-and-restore.md)), health checks, and the git-remote backup pattern.

**Capture:** if the harness persists session transcripts, export them into `kb/<name>/raw/chat-transcripts/` and append to `CHAT_INBOX.md` — the chat-input style then processes them (LOW confidence, verified before the wiki).

See *The Harness Layer* in [architecture.md](architecture.md) for the client-class comparison and Activity Level ceiling.

### Optional external tools (not bundled)

Some scripts shell out to third-party binaries that KBS does **not** ship. Install them yourself
if you want the feature; `scripts/doctor.sh` reports which are present.

| Tool | Feature | Source / install | Pin it? |
|---|---|---|---|
| `graphify` | Knowledge-graph indexing (`scripts/graphify-index.sh`) | Install separately; **pin a known version** and record it here — the wrapper targets a specific CLI surface (`--mode deep`, `--backend`, `--code-only`) that can change between releases | Pin the version you validated; re-run `graphify-index.sh` after any upgrade |
| `ollama` | Local RAG embeddings (`scripts/rag-index.sh`) | `curl -fsSL https://ollama.com/install.sh \| sh`; `ollama pull nomic-embed-text` | Model name is overridable via `KBS_RAG_MODEL` |
| `yt-dlp` + `ffmpeg` | YouTube ingest (`scripts/youtube-ingest.sh`) | `pipx install yt-dlp`; `apt install ffmpeg` | — |
| `timeout` | Bounds long operations | GNU coreutils; macOS: `brew install coreutils` (`gtimeout`) | — |

KBS's own scripts are versioned with the repo (`VERSION`); these external tools are not, so
their behaviour is outside KBS's test coverage. If a feature misbehaves, check the tool version
first — see [version-advising.md](version-advising.md).

### Provider credentials
Set the key for whichever provider you use (e.g. Anthropic, OpenAI, local Ollama needs none):
```bash
export ANTHROPIC_API_KEY="..."     # ~/.bashrc / ~/.zshrc — or your provider's var
```
```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "...", "User")
```
Or, for local models (Ollama/llama.cpp), no key is needed.

> **Note:** `LLM_CLIENT` in `.env.template` is informational only — KBS scripts never read it. Any LLM works.

---

## Verification

```bash
~/kbs/scripts/status.sh
```
Expected on a fresh install: 0 topics, 0 pending, "Last close: Never". Then run the Initial Setup prompt (PROMPTS.md) and your first close.

---

## Chat Adapter Setup

```bash
# pipe / file capture
echo "test insight" | ~/kbs/scripts/chat-adapter.sh

# webhook server (stdlib only, no pip installs)
python3 ~/kbs/scripts/chat-api-adapter.py --server --port 8080
curl -X POST http://localhost:8080/capture -H "Content-Type: application/json" \
  -d '{"content": "test", "model": "any-llm"}'
```

---

## Scheduling (Level 1+)

The bundled `health-check.sh` sends a **desktop notification reminder** — it does not call an LLM itself. Automating the LLM call requires an LLM CLI of your choice (e.g., Anthropic's CLI, `llm` by Simon Willison, or Ollama); a commented stub at the bottom of the script shows where to wire it in.

```cron
# crontab -e
0 17 * * *  ~/kbs/scripts/auto-close.sh      # daily close nudge + streak report
0 9 * * 1-5 ~/kbs/scripts/due-actions.sh     # weekday action reminders
0 10 1 * *  ~/kbs/scripts/health-check.sh    # monthly health-check reminder
```

Windows Task Scheduler:
```powershell
$Action  = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-File $env:USERPROFILE\kbs\scripts\windows\status.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At "5:00PM"
Register-ScheduledTask -TaskName "KBS Daily Reminder" -Action $Action -Trigger $Trigger
```

---

## Version Control, Backup, Rollback

```bash
cd ~/kbs && git init && git add . && git commit -m "KBS initial"   # .gitignore pre-configured

# backup: git-remote pattern — see docs/backup-and-restore.md (nightly-backup.sh)

# rollback a wiki change from snapshot
cp -r ~/kbs/kb/main/wiki/snapshots/[date]/* ~/kbs/kb/main/wiki/topics/
```

## Local Topic Search (Large KBs)

For KBs with 100+ topics, use the lightweight index for rapid topic selection before LLM queries:

```bash
~/kbs/scripts/topic-index.sh                    # rebuild index
~/kbs/scripts/topic-index.sh "metadata crawl"   # search for topics
```

This is not a replacement for LLM synthesis — it accelerates topic finding so the LLM focuses on reasoning, not scanning.

## Semantic Retrieval (RAG)

Optional, local-only semantic index over `wiki/topics/` — no pip dependencies, embeddings via Ollama (default `nomic-embed-text`). The index at `kb/<name>/rag-index/` is git-ignored and regenerable; markdown stays the source of truth.

```bash
~/kbs/scripts/rag-index.sh                    # rebuild semantic index (auto-runs after hourly-ingest)
~/kbs/scripts/rag-query.sh "paraphrase here"  # fuzzy semantic lookup [top-k]
KBS_RAG_MODEL=other ~/kbs/scripts/rag-index.sh  # override embedding model via env
```

Docker: compose wires host Ollama via `host.docker.internal` (default); a fully self-contained `ollama/ollama` sidecar is included as a commented block in `docker/docker-compose.yml` — set `OLLAMA_HOST=http://ollama:11434`.

## Upgrading

**Native install**
```bash
cd /path/to/cloned/kbs && git pull && ./install.sh
```
Safe to re-run — the installer separates system from user files:
- **Refreshed:** `agents.md`, `PROMPTS.md`, `reference/`, `scripts/`, `CHANGELOG.md`, `VERSION`
- **Seeded only when missing (never overwritten):** `INBOX.md`, `FAILURES.md`, `SUCCESSES.md`, `ACTIONS.md`, `DECISIONS.md`, `JOURNAL.md`, `CAREER.md`, `CHAT_INBOX.md`, `SYSTEM.md`, `log.md`, `.gitignore`

It prints which files it kept, and `log.md` gains a `SYSTEM_UPGRADED` entry. Your wiki, raw files, and captures are never touched.

**Docker install**
```bash
git pull && cd docker && docker compose build && docker compose up -d
```
The rebuild refreshes the system files from the new image; everything in the bind-mounted data directory is untouched. No backup step needed — but keeping the data dir in git (above) is still recommended.

**Before advising or depending on a new version, verify it actually activates** — especially features like goal-loop and graphify-index. See **docs/version-advising.md** for the step-by-step runbook (sync → activate → fix as patch → update examples → sign-off).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Installer reports `✗ FAILED` files | Network issue — clone the repo and install locally |
| LLM can't read files | Grant folder permission in the client |
| `Permission denied` | `chmod +x install.sh` |
| Webhook port in use | `--port 8081` |
| Session close does nothing | Check INBOX has entries; confirm the LLM read agents.md *and* reference/session-close.md |
| Streak not tracking | Ensure `~/kbs/log.md` exists and has `SESSION_CLOSE` entries |
| Due actions not notifying | Check `~/kbs/ACTIONS.md` uses `Due: YYYY-MM-DD` format |
| Docker build fails | Ensure Docker is running; `docker system prune` |
| Docker data not visible on host | Set `KBS_HOME` — default bind mount is `<repo>/docker/kbs` |
| Want the shipped template for a kept file | Compare against `templates/<file>` in the repo, then merge manually |

## Uninstall

```bash
rm -rf ~/kbs                                            # native install
cd docker && docker compose down                        # Docker: stop container
rm -rf kbs                                              # Docker: remove the bind-mounted data dir
```
Docker no longer uses named volumes, so `down -v` is not required.
