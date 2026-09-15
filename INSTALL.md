# Installation — KBS V0.114

## One-Command Install

**Linux / macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash
```

**Windows (PowerShell as Administrator)**
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"
```

**From a clone (no network needed for templates)**
```bash
git clone https://github.com/vkanimea/kbs.git && cd kbs
./install.sh            # Linux/macOS
.\install.ps1           # Windows
```

**Custom path / KB name**
```bash
KBS_PATH=/custom/path KB_NAME=myproject ./install.sh
```
```powershell
.\install.ps1 -KbsPath "C:\custom\path" -KbName "myproject"
```

The installer **aborts with an error** if any file fails to install — a partial install never passes silently.

---

## Post-Install (4 Steps)

1. **Grant your LLM client folder access** to `~/kbs`
   (Claude Desktop: Settings → Permissions → Add Folder. Other clients: docs/deployment.md)
2. **Verify:** `~/kbs/scripts/status.sh` (Linux/macOS) or `powershell -File $env:USERPROFILE\kbs\scripts\windows\status.ps1`
3. **Run the Initial Setup prompt** from `~/kbs/PROMPTS.md` in your LLM client
4. **Close your first session:** `Follow agents.md. Close session for main`

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `curl: command not found` | `sudo apt install curl` / `brew install curl` |
| `Permission denied` | `chmod +x install.sh && ./install.sh` |
| ExecutionPolicy error (Windows) | Run PowerShell as Administrator |
| Installer reports FAILED files | Check network, or clone the repo and install locally |
| LLM can't read files | Add `~/kbs` to client folder permissions |

## Uninstall

```bash
rm -rf ~/kbs                                          # Linux/macOS
Remove-Item -Recurse -Force "$env:USERPROFILE\kbs"    # Windows
```

Full deployment options (Docker, Ollama, scheduling, backup): [docs/deployment.md](docs/deployment.md)
