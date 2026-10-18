# Knowledge Base System (KBS) — Windows PowerShell Installer
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/vkanimea/kbs/main/install.ps1 | iex"
#   .\install.ps1 -KbsPath "C:\custom\path" -KbName "myproject"
#   $env:KBS_REF="<tag>"; .\install.ps1         # pin to a specific tag
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

# Version — read from the repo's VERSION file so this script never drifts from the release.
# If KBS_REF is set, fetch from that tag instead of main.
$Ref = $env:KBS_REF
if (-not $Ref) { $Ref = "main" }

$Version = ""
if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "VERSION"))) {
    $Version = (Get-Content (Join-Path $ScriptDir "VERSION") -Raw).Trim()
}
if (-not $Version) {
    try { 
        $VersionUrl = $RepoUrl -replace "main", $Ref
        $Version = (Invoke-WebRequest -Uri "$VersionUrl/VERSION" -UseBasicParsing -ErrorAction Stop).Content.Trim() 
    } catch { }
}
# Fallback to 'unknown' instead of a stale hard-coded version
if (-not $Version) { $Version = "unknown" }

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host ("║{0,-62}║" -f "       Knowledge Base System (KBS) V$Version Installer") -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# If version is unknown, warn the user
if ($Version -eq "unknown") {
    Write-Host "⚠️  Could not determine version from repo — install may be from unpinned source" -ForegroundColor Yellow
}

Write-Host "📍 Path : $KbsPath" -ForegroundColor Yellow
Write-Host "📚 KB   : $KbName"  -ForegroundColor Yellow
Write-Host ""

# ─── Directories ───────────────────────────────────────────────────────────────
@(
    "$KbsPath\reference",
    "$KbsPath\scripts\analyze-sessions",
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

# Detect fresh install vs upgrade (for the audit log event name)
$InstanceExisted = Test-Path "$KbsPath\log.md"

# SHA256SUMS support (optional) — if present in repo at the pinned REF, verify downloads
$Sha256Sums = $null
$Sha256SumsUrl = $RepoUrl -replace "main", $Ref
$Sha256SumsUrl += "/SHA256SUMS"
try { 
    $Sha256Sums = (Invoke-WebRequest -Uri $Sha256SumsUrl -UseBasicParsing -ErrorAction SilentlyContinue).Content.Trim()
} catch { }

function Get-ExpectedHash {
    param([string]$RelPath)
    if ($Sha256Sums) {
        $line = $Sha256Sums | Select-String -Pattern " $RelPath$"
        if ($line) { return ($line -split '\s+')[0] }
    }
    return $null
}

function Install-KbsFile {
    param([string]$Src, [string]$Dst)
    $local = if ($ScriptDir) { Join-Path $ScriptDir ($Src -replace "/", "\") } else { "" }
    if ($local -and (Test-Path $local)) {
        Copy-Item $local $Dst -Force
        Write-Host "  ✓ $Src (local)" -ForegroundColor Green
    } else {
        try {
            $url = $RepoUrl -replace "main", $Ref
            $url += "/$Src"
            Invoke-WebRequest -Uri $url -OutFile $Dst -ErrorAction Stop
            Write-Host "  ✓ $Src" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ $Src — FAILED" -ForegroundColor Red
            $script:Failed = $true
        }
    }
    # Verify checksum if SHA256SUMS available
    $expected = Get-ExpectedHash $Src
    if ($expected) {
        $actual = (Get-FileHash $Dst -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected.ToLower()) {
            Write-Host "  ✗ $Src — CHECKSUM MISMATCH (expected $expected, got $actual)" -ForegroundColor Red
            $script:Failed = $true
        }
    }
}

# Seed a user-owned file only if it does not already exist.
$script:Kept = @()
function Install-KbsFilePreserve {
    param([string]$Src, [string]$Dst)
    if (Test-Path $Dst) {
        $script:Kept += (Split-Path $Dst -Leaf)
        return
    }
    Install-KbsFile $Src $Dst
}

$script:Failed = $false

Write-Host "📝 Installing system files..." -ForegroundColor Cyan
@("agents.md","PROMPTS.md","CONVENTIONS.md") |
  ForEach-Object { Install-KbsFile "templates/$_" "$KbsPath\$_" }
@("session-close.md","ingestion.md","chat-input.md","failures.md","successes.md","actions.md","journal.md","learning.md","session-analysis.md","writing-style.md","health-check.md","atoms.md") |
  ForEach-Object { Install-KbsFile "templates/reference/$_" "$KbsPath\reference\$_" }
Install-KbsFile "CHANGELOG.md" "$KbsPath\CHANGELOG.md"
Install-KbsFile "VERSION" "$KbsPath\VERSION"

Write-Host "📚 Installing docs..." -ForegroundColor Cyan
@("architecture.md","backup-and-restore.md","connector-hygiene.md","deployment.md","glossary.md","goal-spec.md","input-output-guide.md","security.md","swot-analysis.md","user-guide.md","version-advising.md") |
  ForEach-Object { Install-KbsFile "docs/$_" "$KbsPath\docs\$_" }

Write-Host "🗂  Preserving your files (seed if missing)..." -ForegroundColor Cyan
@("SYSTEM.md","DECISIONS.md","INBOX.md","CHAT_INBOX.md","FAILURES.md","SUCCESSES.md","CAREER.md","ACTIONS.md","JOURNAL.md","log.md") |
  ForEach-Object { Install-KbsFilePreserve "templates/$_" "$KbsPath\$_" }
if ($script:Kept.Count -gt 0) {
    Write-Host "  kept: $($script:Kept -join ' ')" -ForegroundColor Yellow
    Write-Host "  (shipped templates for these live in templates/ — diff only if you want header updates)" -ForegroundColor Yellow
}

Write-Host "🔧 Installing scripts..." -ForegroundColor Cyan
@("chat-adapter.sh","chat-api-adapter.py","health-check.sh","status.sh","auto-close.sh","due-actions.sh","topic-index.sh","youtube-ingest.sh","hourly-ingest.sh","git-credential-env.sh","nightly-backup.sh","rag.py","rag-index.sh","rag-query.sh","goal-loop.sh","graphify-index.sh","kbs-sync.sh","kbs-drift-check.sh","model-config.sh","kbs-lint.sh","ingest-freshness.sh","staleness-sweep.sh","kbs-provenance.sh","backup-catchup.sh","backup-verify.sh") |
  ForEach-Object { Install-KbsFile "scripts/$_" "$KbsPath\scripts\$_" }
@("sessions.py","cost.py","prompts.py","search.py","show_session.py","README.md") |
  ForEach-Object { Install-KbsFile "scripts/analyze-sessions/$_" "$KbsPath\scripts\analyze-sessions\$_" }
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
# KBS V$Version — copy to .env and edit
KBS_PATH=$KbsPath
KB_NAME=$KbName
AUTO_INGEST=false
LLM_CLIENT=any
ACTIVITY_LEVEL=0
"@ | Out-File "$KbsPath\.env.template" -Encoding utf8

$Event = if ($InstanceExisted) { "SYSTEM_UPGRADED" } else { "SYSTEM_CREATED" }
Add-Content "$KbsPath\log.md" "`n## $Timestamp | $Event | V$Version | Path: $KbsPath | KB: $KbName"

# .gitignore: seed only — never overwrite rules you have added
if (-not (Test-Path "$KbsPath\.gitignore")) {
    ".env`n*.log`n*.tmp`nkb/*/wiki/snapshots/" | Out-File "$KbsPath\.gitignore" -Encoding utf8
}

# Ensure SHA256SUMS if available
if ($Sha256Sums) {
    $Sha256Sums | Out-File "$KbsPath\SHA256SUMS" -Encoding utf8
}

# Credential helper registration (idempotent)
git -C $KbsPath config credential.helper '!bash scripts/git-credential-env.sh' 2>$null

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