# KBS Status Check - Windows PowerShell (V0.115)
# Usage: powershell -File $env:USERPROFILE\kbs\scripts\windows\status.ps1
# NOTE: ASCII-only output for PowerShell 5.1 console compatibility.

$KbsPath = if ($env:KBS_PATH) { $env:KBS_PATH } else { "$env:USERPROFILE\kbs" }
$KbName  = if ($env:KB_NAME)  { $env:KB_NAME  } else { "main" }

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "    Knowledge Base System - Status (V0.115)   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "KBS Path : $KbsPath" -ForegroundColor Yellow
Write-Host "KB Name  : $KbName"  -ForegroundColor Yellow
Write-Host ""

# Topics
$Topics = (Get-ChildItem "$KbsPath\kb\$KbName\wiki\topics\*.md" -ErrorAction SilentlyContinue).Count
Write-Host "[TOPICS]       : $Topics"

# Raw files
$Raw = (Get-ChildItem "$KbsPath\kb\$KbName\raw" -Include "*.md","*.txt" -Recurse -ErrorAction SilentlyContinue).Count
Write-Host "[RAW]          : $Raw"

# Outputs
$Outputs = (Get-ChildItem "$KbsPath\kb\$KbName\outputs\*.md" -ErrorAction SilentlyContinue).Count
Write-Host "[OUTPUTS]      : $Outputs"

# Pending
$Pending = (Get-ChildItem "$KbsPath\kb\$KbName\outputs\pending-*.md" -ErrorAction SilentlyContinue).Count
if ($Pending -gt 0) {
    Write-Host "[PENDING]      : $Pending - review needed" -ForegroundColor Red
} else {
    Write-Host "[PENDING]      : $Pending" -ForegroundColor Green
}

# Failures
$FailuresPath = "$KbsPath\FAILURES.md"
if (Test-Path $FailuresPath) {
    $Failures   = (Select-String -Path $FailuresPath -Pattern "^## 20" -ErrorAction SilentlyContinue).Count
    $Unresolved = (Select-String -Path $FailuresPath -Pattern "Resolved: No" -ErrorAction SilentlyContinue).Count
    Write-Host "[FAILURES]     : $Failures"
    if ($Unresolved -gt 0) {
        Write-Host "  Unresolved  : $Unresolved - action needed" -ForegroundColor Red
    } else {
        Write-Host "  Unresolved  : 0" -ForegroundColor Green
    }
}

# Achievements
$CareerPath = "$KbsPath\CAREER.md"
if (Test-Path $CareerPath) {
    $Achievements = (Select-String -Path $CareerPath -Pattern "^## 20" -ErrorAction SilentlyContinue).Count
    Write-Host "[ACHIEVEMENTS] : $Achievements"
}

# Last session close
$LogPath = "$KbsPath\log.md"
if (Test-Path $LogPath) {
    $CloseMatches = Select-String -Path $LogPath -Pattern "SESSION_CLOSE" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Line -notmatch '\[ts\]' }
    $LastMatch = $CloseMatches | Select-Object -Last 1
    if ($LastMatch) {
        $LastClose = $LastMatch.Line.Substring(0, $LastMatch.Line.IndexOf("|")).Trim()
        Write-Host "[LAST CLOSE]   : $LastClose"
    } else {
        Write-Host "[LAST CLOSE]   : Never - run session close today" -ForegroundColor Red
    }
}

# Last health check
$hcFile = Get-ChildItem "$KbsPath\kb\$KbName\outputs\health-check-*.md" -ErrorAction SilentlyContinue |
          Sort-Object Name | Select-Object -Last 1
if ($hcFile) {
    $LatestHC = $hcFile.Name -replace "health-check-","" -replace "\.md$",""
    Write-Host "[HEALTH CHECK] : $LatestHC"
} else {
    Write-Host "[HEALTH CHECK] : None - run monthly health check" -ForegroundColor Yellow
}

# Close streak
$StreakFile = "$KbsPath\.close-streak"
$Streak = 0
if (Test-Path $StreakFile) {
    $content = (Get-Content $StreakFile -Raw).Trim()
    if ($content -match '^\d+$') { $Streak = [int]$content }
}
if ($Streak -gt 2) {
    Write-Host "[STREAK]       : $Streak days" -ForegroundColor Green
} elseif ($Streak -gt 0) {
    Write-Host "[STREAK]       : $Streak days" -ForegroundColor Green
} else {
    Write-Host "[STREAK]       : Broken or not started" -ForegroundColor Red
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