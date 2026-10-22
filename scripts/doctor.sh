#!/bin/bash
# doctor.sh — KBS environment preflight.
#
# Reports which tools KBS needs (required) and which unlock optional features,
# and whether the data instance looks correctly wired. Read-only: changes nothing.
#
# Usage:  scripts/doctor.sh
# Exit:   0 = all REQUIRED tools present; 1 = one or more required tools missing.
#
# Required tools are those the core loop (ingest, close, backup, lint, sync)
# invokes. Optional tools gate individual features; their absence is not an error.

set -u

PASS=0; WARN=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[0;32mOK\033[0m    %-14s %s\n' "$1" "$2"; }
warn() { WARN=$((WARN+1)); printf '  \033[0;33mWARN\033[0m  %-14s %s\n' "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[0;31mFAIL\033[0m  %-14s %s\n' "$1" "$2"; }

have() { command -v "$1" >/dev/null 2>&1; }

echo "KBS doctor — environment preflight"
echo

# ─── Required tools ────────────────────────────────────────────────────────────
echo "Required:"
for t in bash git python3 curl sed awk grep find date; do
  if have "$t"; then ok "$t" "$(command -v "$t")"
  else bad "$t" "not found — the core loop will fail without it"; fi
done

# timeout: GNU coreutils. macOS has no stock `timeout`; scripts fall back to
# running without a limit, so this is a WARN, not a FAIL.
if have timeout; then ok "timeout" "$(command -v timeout)"
elif have gtimeout; then ok "timeout" "gtimeout (Homebrew coreutils) at $(command -v gtimeout)"
else warn "timeout" "absent (stock macOS) — long operations run without a time limit"; fi

# rsync: used by the offsite/backup path.
if have rsync; then ok "rsync" "$(command -v rsync)"
else warn "rsync" "absent — needed only for the rsync-based backup path"; fi

# ─── Optional tools (gate features) ────────────────────────────────────────────
echo
echo "Optional (feature gates):"
declare -A OPT=(
  [yt-dlp]="YouTube ingest (scripts/youtube-ingest.sh)"
  [ffmpeg]="audio extraction for transcription"
  [ollama]="local RAG embeddings (scripts/rag-index.sh)"
  [graphify]="knowledge-graph indexing (scripts/graphify-index.sh)"
  [pi]="agent harness (any harness works; pi is the reference)"
)
for t in yt-dlp ffmpeg ollama graphify pi; do
  if have "$t"; then ok "$t" "${OPT[$t]}"
  else warn "$t" "absent — ${OPT[$t]}"; fi
done

# ─── Instance wiring ───────────────────────────────────────────────────────────
echo
echo "Instance:"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KBS_PATH="${KBS_PATH:-$ROOT}"
if [ -f "$KBS_PATH/VERSION" ]; then ok "VERSION" "$(tr -d '[:space:]' < "$KBS_PATH/VERSION") at $KBS_PATH"
else warn "VERSION" "not found under $KBS_PATH"; fi

if [ -f "$KBS_PATH/agents.md" ]; then ok "agents.md" "present — point your harness at it each session"
else warn "agents.md" "not found — the harness has no instructions to load"; fi

if [ -f "$KBS_PATH/.env" ]; then ok ".env" "present (secrets configured)"
else warn ".env" "absent — optional; copy from .env.template if you use remote backup"; fi

if [ -d "$KBS_PATH/kb" ]; then ok "kb/" "present"
else warn "kb/" "absent — run install.sh to scaffold the knowledge bases"; fi

# System repo discoverable? (needed for kbs-sync.sh / drift check)
SYSTEM_REPO="${KBS_SYSTEM_REPO:-}"
if [ -n "$SYSTEM_REPO" ] && [ -d "$SYSTEM_REPO" ]; then ok "system repo" "$SYSTEM_REPO (KBS_SYSTEM_REPO)"
elif [ -d "$HOME/kbs-system" ]; then ok "system repo" "~/kbs-system (auto-discovered)"
elif [ -d "$HOME/kbs" ] && [ -f "$HOME/kbs/install.sh" ] && [ "$HOME/kbs" != "$KBS_PATH" ]; then ok "system repo" "~/kbs (auto-discovered)"
else warn "system repo" "not found — set KBS_SYSTEM_REPO to run kbs-sync.sh / drift check"; fi

# ─── Summary ───────────────────────────────────────────────────────────────────
echo
printf 'doctor: %d ok, %d warn, %d fail\n' "$PASS" "$WARN" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "Missing REQUIRED tools — install them before running KBS."
  exit 1
fi
echo "All required tools present. Warnings are optional features only."
exit 0
