# KBS Deployment Guide — V11.3

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
The compose file ([docker/docker-compose.yml](../docker/docker-compose.yml)) persists wiki, raw, and outputs as named volumes and exposes port 8080 for the chat webhook.

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
cd ~/kbs && git init && git add . && git commit -m "KBS V11.3 initial"   # .gitignore pre-configured

tar -czf kbs-backup-$(date +%Y%m%d).tar.gz ~/kbs                          # backup

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

## Upgrading

```bash
tar -czf kbs-pre-upgrade.tar.gz ~/kbs        # backup first
cd /path/to/cloned/kbs && git pull && ./install.sh
```
Your wiki, raw files, and capture-file contents are preserved; template files are refreshed. Diff your INBOX/FAILURES/CAREER files after upgrade if you've customised their headers.

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

## Uninstall

```bash
rm -rf ~/kbs
docker compose -f docker/docker-compose.yml down -v    # if using Docker
```
