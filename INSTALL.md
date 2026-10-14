# Installation — KBS

## One-Command Install

**Linux / macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/vkanimea/kbs/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"
```

> **Inspect before you run (recommended).** Piping a remote script straight into a shell is the most convenient but least auditable path. For anything but a throwaway install, download the installer, read it, then run it from a pinned release tag with a verified checksum:
>
> ```bash
> # Linux/macOS
> curl -fsSL -o install.sh https://raw.githubusercontent.com/vkanimea/kbs/v0.125/install.sh
> less install.sh                      # review
> sha256sum -c SHA256SUMS --ignore-missing   # verify against the release checksums (if published)
> bash install.sh
> ```
>
> **Administrator is only needed on Windows** if KBS writes to a system-owned path; installing to your user folder does not require elevation.

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
   (Any LLM works — folder read/write is all that's needed; see `docs/deployment.md` for examples)
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
| Sceptical of piping remote code | Download, inspect, then run from a pinned tag (see above) |

## Uninstall

```bash
rm -rf ~/kbs                                          # Linux/macOS
Remove-Item -Recurse -Force "$env:USERPROFILE\kbs"    # Windows
```

Full deployment options (Docker, Ollama, scheduling, backup): [docs/deployment.md](docs/deployment.md)
