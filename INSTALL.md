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
> curl -fsSL -o install.sh https://raw.githubusercontent.com/vkanimea/kbs/<TAG>/install.sh
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

## Prerequisites

KBS is plain markdown + shell. The **required** tools are present on virtually every Linux and
macOS system; the **optional** ones unlock individual features. Run `scripts/doctor.sh` after
installing to confirm what is present.

| Tool | Required? | Needed for | Install (Debian/Ubuntu) | Install (macOS) |
|---|---|---|---|---|
| `bash` | **yes** | every script | preinstalled | preinstalled |
| `git` | **yes** | history, backup, sync | `sudo apt install git` | `brew install git` |
| `python3` | **yes** | RAG, linters, adapters | `sudo apt install python3` | `brew install python3` |
| `curl` | **yes** | installer, remote fetch | `sudo apt install curl` | preinstalled |
| `sed` `awk` `grep` `find` `date` | **yes** | text handling | coreutils | preinstalled |
| `timeout` | recommended | bounds long operations | coreutils | `brew install coreutils` (`gtimeout`) |
| `rsync` | optional | rsync backup path | `sudo apt install rsync` | preinstalled |
| `ollama` | optional | local RAG embeddings | [ollama.com](https://ollama.com) | `brew install ollama` |
| `yt-dlp` + `ffmpeg` | optional | YouTube ingest | `pipx install yt-dlp` / `apt install ffmpeg` | `brew install yt-dlp ffmpeg` |
| `graphify` | optional | knowledge-graph indexing | see `docs/deployment.md` (source + version) | same |
| An agent harness | **yes (for L2–3)** | executing scripts, git, schedules | any tool-using agent — see `docs/deployment.md` | same |

> **macOS note:** stock macOS has no `timeout`. KBS scripts detect this and run the operation
> without a time limit rather than failing; install coreutils (`gtimeout`) to restore the bounds.
> `kbs-provenance.sh` uses a portable 8-day date computation that works on both GNU and BSD `date`.

---

## Post-Install (4 Steps)

0. **Check your environment:** `~/kbs/scripts/doctor.sh` — reports required vs optional tools
   and whether the instance is wired correctly. Exits non-zero only if a *required* tool is missing.
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
| Unsure what's missing | `~/kbs/scripts/doctor.sh` — lists required vs optional tools |
| `timeout: command not found` (macOS) | Harmless — scripts run without a limit; `brew install coreutils` for `gtimeout` |
| Sceptical of piping remote code | Download, inspect, then run from a pinned tag (see above) |

## Uninstall

```bash
rm -rf ~/kbs                                          # Linux/macOS
Remove-Item -Recurse -Force "$env:USERPROFILE\kbs"    # Windows
```

Full deployment options (Docker, Ollama, scheduling, backup): [docs/deployment.md](docs/deployment.md)
