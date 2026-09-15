# KBS Status Check — Windows PowerShell (V0.113)
# Usage: powershell -File $env:USERPROFILE\kbs\scripts\windows\status.ps1

$KbsPath = if ($env:KBS_PATH) { $env:KBS_PATH } else { "$env:USERPROFILE\kbs" }
$KbName  = if ($env:KB_NAME)  { $env:KB_NAME  } else { "main" }

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Knowledge Base System — Status              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "KBS Path : $KbsPath" -ForegroundColor Yellow
Write-Host "KB Name  : $KbName"  -ForegroundColor Yellow
Write-Host ""

# Topics
$Topics = (Get-ChildItem "$KbsPath\kb\$KbName\wiki\topics\*.md" -ErrorAction SilentlyContinue).Count
Write-Host "📚 Topics           : $Topics"

# Raw files
$Raw = (Get-ChildItem "$KbsPath\kb\$KbName\raw" -Include "*.md","*.txt" -Recurse -ErrorAction SilentlyContinue).Count
Write-Host "📄 Raw files        : $Raw"

# Outputs
$Outputs = (Get-ChildItem "$KbsPath\kb\$KbName\outputs\*.md" -ErrorAction SilentlyContinue).Count
Write-Host "📤 Outputs          : $Outputs"

# Pending
$Pending = (Get-ChildItem "$KbsPath\kb\$KbName\outputs\pending-*.md" -ErrorAction SilentlyContinue).Count
if ($Pending -gt 0) {
    Write-Host "⏳ Pending approvals: $Pending — review needed" -ForegroundColor Red
} else {
    Write-Host "⏳ Pending approvals: $Pending" -ForegroundColor Green
}

# Failures
$FailuresPath = "$KbsPath\FAILURES.md"
if (Test-Path $FailuresPath) {
    $Failures   = (Select-String -Path $FailuresPath -Pattern "^## 20" -ErrorAction SilentlyContinue).Count
    $Unresolved = (Select-String -Path $FailuresPath -Pattern "Resolved: No" -ErrorAction SilentlyContinue).Count
    Write-Host "⚠️  Total failures  : $Failures"
    if ($Unresolved -gt 0) {
        Write-Host "   Unresolved     : $Unresolved — action needed" -ForegroundColor Red
    } else {
        Write-Host "   Unresolved     : 0" -ForegroundColor Green
    }
}

# Achievements
$CareerPath = "$KbsPath\CAREER.md"
if (Test-Path $CareerPath) {
    $Achievements = (Select-String -Path $CareerPath -Pattern "^## 20" -ErrorAction SilentlyContinue).Count
    Write-Host "🏆 Achievements    : $Achievements"
}

# Last session close
$LogPath = "$KbsPath\log.md"
if (Test-Path $LogPath) {
    $LastClose = (Select-String -Path $LogPath -Pattern "SESSION_CLOSE" -ErrorAction SilentlyContinue |
                  Select-Object -Last 1)?.Line -split "\|" | Select-Object -First 1
    if ($LastClose) {
        Write-Host "🕐 Last close      : $($LastClose.Trim())"
    } else {
        Write-Host "🕐 Last close      : Never — run session close today" -ForegroundColor Red
    }
}

# Last health check
$LatestHC = (Get-ChildItem "$KbsPath\kb\$KbName\outputs\health-check-*.md" -ErrorAction SilentlyContinue |
             Sort-Object Name | Select-Object -Last 1)?.Name -replace "health-check-","" -replace ".md",""
if ($LatestHC) {
    Write-Host "🔍 Last health check: $LatestHC"
} else {
    Write-Host "🔍 Last health check: None — run monthly health check" -ForegroundColor Yellow
}

# Close streak
$StreakFile = "$KbsPath\.close-streak"
$Streak = if (Test-Path $StreakFile) { [int](Get-Content $StreakFile -Raw).Trim() } else { 0 }
if ($Streak -gt 2) {
    Write-Host "🔥 Close streak    : $Streak days" -ForegroundColor Green
} elseif ($Streak -gt 0) {
    Write-Host "✅ Close streak    : $Streak days" -ForegroundColor Green
} else {
    Write-Host "⚠️  Close streak    : Broken or not started" -ForegroundColor Red
}

Write-Host ""
Write-Host "Quick prompts:" -ForegroundColor Cyan
Write-Host "  Session close : Follow agents.md. Close session for $KbName"
Write-Host "  Ingest        : Follow agents.md. Ingest $KbName"
Write-Host "  Health check  : Follow agents.md and SYSTEM.md. Run health check on $KbName"
Write-Host "  Show pending  : Follow agents.md. Show me all pending approvals"
Write-Host ""
Write-Host "Helper scripts:" -ForegroundColor Cyan
Write-Host "  Auto-close    : $KbsPath\scripts\auto-close.sh (WSL) or run manually"
Write-Host "  Due actions   : $KbsPath\scripts\due-actions.sh (WSL) or run manually"
Write-Host "  Topic search  : $KbsPath\scripts\topic-index.sh 'search term' (WSL)"
Write-Host ""
