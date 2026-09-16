# KBS Deployment Guide — V0.115

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

**Make the data directory your private repo** — it is a complete KBS instance, so the V0.115 backup pattern applies unchanged:
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

### Claude Desktop (easiest)
Settings → Permissions → Add Folder → `~/kbs`. Test with the Initial Setup prompt from PROMPTS.md.

### Ollama + Open WebUI (free, local)
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.3
docker run -d -p 3000:8080 -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
```
Open http://localhost:3000 and point the workspace at `~/kbs`. Windows: use WSL2 (`wsl --install`).

### Agent Harnesses (enables levels 2–3)
A chat client can read and write KBS files, but only a **tool-using agent harness** can run the scripts, git operations, and schedules that higher Activity Levels need. Use one when you want routine automation or autonomy:

- **What to look for:** folder access to `~/kbs`, file read/write, a shell, and git. Nothing KBS-specific is required — the interface is markdown + git.
- **Examples:** opencode, pi, Claude Code, or any agent with shell + file tools.
- **What it unlocks:** `hourly-ingest.sh` scheduling, semantic index rebuilds, session close that commits/pushes (see [backup-and-restore.md](backup-and-restore.md)), health checks, and the git-remote backup pattern.
- **Capture:** if the harness persists session transcripts, export them into `kb/<name>/raw/chat-transcripts/` and append to `CHAT_INBOX.md` — the chat-input style then processes them (LOW confidence, verified before the wiki).

See *The Harness Layer* in [architecture.md](architecture.md) for the client-class comparison and Activity Level ceiling.

### API Keys
```bash
export ANTHROPIC_API_KEY="..."     # ~/.bashrc / ~/.zshrc
```
```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "...", "User")
```
Or copy `.env.template` to `.env` and edit.

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
  -d '{"content": "test", "model": "claude"}'
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
cd ~/kbs && git init && git add . && git commit -m "KBS V0.115 initial"   # .gitignore pre-configured

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
