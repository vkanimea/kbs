# Knowledge Base System (KBS) V11.3 — Windows PowerShell Installer
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"
#   .\install.ps1 -KbsPath "C:\custom\path" -KbName "myproject"
#
# If run from a cloned repo, templates are copied locally. Otherwise downloaded;
# any failure aborts loudly.

param(
    [string]$KbsPath = $env:KBS_PATH,
    [string]$KbName  = $env:KB_NAME
)

if (-not $KbsPath) { $KbsPath = "$HOME\kbs" }
if (-not $KbName)  { $KbName  = "main" }

$RepoUrl   = "https://raw.githubusercontent.com/vkanimea/kbs/main"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "" }

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       Knowledge Base System (KBS) V11.3 Installer            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "📍 Path : $KbsPath" -ForegroundColor Yellow
Write-Host "📚 KB   : $KbName"  -ForegroundColor Yellow
Write-Host ""

# ─── Directories ───────────────────────────────────────────────────────────────
@(
    "$KbsPath\reference",
    "$KbsPath\kb\$KbName\raw\chat-transcripts",
    "$KbsPath\kb\$KbName\raw-assets\pdfs",
    "$KbsPath\kb\$KbName\raw-assets\images",
    "$KbsPath\kb\$KbName\wiki\topics",
    "$KbsPath\kb\$KbName\wiki\snapshots",
    "$KbsPath\kb\$KbName\outputs",
    "$KbsPath\scripts\windows",
    "$KbsPath\docs"
) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
Write-Host "✅ Directories created" -ForegroundColor Green

# ─── File installer ────────────────────────────────────────────────────────────
$script:Failed = $false
function Install-KbsFile {
    param([string]$Src, [string]$Dst)
    $local = if ($ScriptDir) { Join-Path $ScriptDir ($Src -replace "/", "\") } else { "" }
    if ($local -and (Test-Path $local)) {
        Copy-Item $local $Dst -Force
        Write-Host "  ✓ $Src (local)" -ForegroundColor Green
        return
    }
    try {
        Invoke-WebRequest -Uri "$RepoUrl/$Src" -OutFile $Dst -ErrorAction Stop
        Write-Host "  ✓ $Src" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $Src — FAILED" -ForegroundColor Red
        $script:Failed = $true
    }
}

Write-Host "📝 Installing templates..." -ForegroundColor Cyan
@("agents.md","SYSTEM.md","DECISIONS.md","INBOX.md","CHAT_INBOX.md","FAILURES.md","SUCCESSES.md","CAREER.md","ACTIONS.md","JOURNAL.md","PROMPTS.md","log.md") |
  ForEach-Object { Install-KbsFile "templates/$_" "$KbsPath\$_" }
@("session-close.md","ingestion.md","chat-input.md","failures.md","successes.md","actions.md","journal.md","health-check.md") |
  ForEach-Object { Install-KbsFile "templates/reference/$_" "$KbsPath\reference\$_" }
Install-KbsFile "CHANGELOG.md" "$KbsPath\CHANGELOG.md"

Write-Host "🔧 Installing scripts..." -ForegroundColor Cyan
@("chat-adapter.sh","chat-api-adapter.py","health-check.sh","status.sh","auto-close.sh","due-actions.sh","topic-index.sh","youtube-ingest.sh","hourly-ingest.sh") |
  ForEach-Object { Install-KbsFile "scripts/$_" "$KbsPath\scripts\$_" }
Install-KbsFile "scripts/windows/status.ps1" "$KbsPath\scripts\windows\status.ps1"

# Install examples (optional — copy locally if available, never fail on download)
Write-Host "📦 Installing starter KB..." -ForegroundColor Cyan
$examplesLocal = if ($ScriptDir) { Join-Path $ScriptDir "examples\starter-kb" } else { "" }
if ($examplesLocal -and (Test-Path $examplesLocal)) {
    New-Item -ItemType Directory -Force -Path "$KbsPath\examples" | Out-Null
    Copy-Item $examplesLocal "$KbsPath\examples\starter-kb" -Recurse -Force
    Write-Host "  ✓ examples/starter-kb (local)" -ForegroundColor Green
}

if ($script:Failed) {
    Write-Host ""
    Write-Host "❌ INSTALLATION INCOMPLETE — one or more files failed to install." -ForegroundColor Red
    Write-Host "   Check your network, or clone the repo and run .\install.ps1 locally:" -ForegroundColor Red
    Write-Host "   git clone https://github.com/vkanimea/kbs.git; cd kbs; .\install.ps1"
    exit 1
}

# ─── Generated files ───────────────────────────────────────────────────────────
@"
# KBS V11.3 — copy to .env and edit
KBS_PATH=$KbsPath
KB_NAME=$KbName
AUTO_INGEST=false
LLM_CLIENT=claude
ACTIVITY_LEVEL=0
"@ | Out-File "$KbsPath\.env.template" -Encoding utf8

Add-Content "$KbsPath\log.md" "`n## $Timestamp | SYSTEM_CREATED | V11.3 | Path: $KbsPath | KB: $KbName"

".env`n*.log`n*.tmp`nkb/*/wiki/snapshots/" | Out-File "$KbsPath\.gitignore" -Encoding utf8

# ─── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                 INSTALLATION COMPLETE  ✅                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. LLM client: grant folder access to $KbsPath"
Write-Host "  2. Optional: copy starter KB → Copy-Item $KbsPath\examples\starter-kb\wiki\topics\* $KbsPath\kb\$KbName\wiki\topics\ -Recurse"
Write-Host "  3. Verify: powershell -File $KbsPath\scripts\windows\status.ps1"
Write-Host "  4. In your LLM client, run the Initial Setup prompt from PROMPTS.md"
Write-Host "  5. After every session: Follow agents.md. Close session for $KbName"
Write-Host ""
Write-Host "A session without a close is a session without learning." -ForegroundColor Yellow
