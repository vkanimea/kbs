#!/bin/bash
# test-hourly-ingest.sh — deterministic tests for the staging-only raw-file lifecycle.
# Runs scripts/hourly-ingest.sh against a temporary KB with a stub environment.
# No LLM, no network. See docs/swot-analysis.md §I2/I5.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INGEST="$SCRIPT_DIR/../scripts/hourly-ingest.sh"
PASS=0; FAIL=0

new_kb() {
  T="$(mktemp -d)"
  mkdir -p "$T/kb/tk/raw" "$T/kb/tk/wiki/topics" "$T/outputs"
  echo test > "$T/kb/tk/wiki/topics/index.md"
  echo "$T"
}

expect_log() { # kb, pattern, label
  local t="$1" pat="$2" label="$3"
  # log.md lives at the KBS root in an instance; tests keep it at $t/log.md
  if grep -q "$pat" "$t/log.md" 2>/dev/null; then PASS=$((PASS+1)); echo "  ok: $label";
  else FAIL=$((FAIL+1)); echo "  FAIL: $label (pattern '$pat' not in log)"; fi
}

# ── 1. Empty raw/ → clean exit, logged ────────────────────────────────────────
T=$(new_kb)
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "No raw files staged" "empty raw/ logs and exits 0"

# ── 2. Referenced file → referenced, file NOT moved ───────────────────────────
T=$(new_kb)
printf '# INBOX\n\n## Unprocessed Entries\n- Source: alpha.md\n  note\n' > "$T/kb/tk/INBOX.md"
echo "alpha content" > "$T/kb/tk/raw/alpha.md"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "referenced=1 orphans=0" "referenced file classified"
[ -f "$T/kb/tk/raw/alpha.md" ] && { PASS=$((PASS+1)); echo "  ok: referenced file stays in raw/"; } || { FAIL=$((FAIL+1)); echo "  FAIL: referenced file was moved"; }

# ── 3. Unreferenced file → orphan reported, never marked processed ────────────
T=$(new_kb)
echo "orphan content" > "$T/kb/tk/raw/beta.md"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "ORPHANS .*beta.md" "orphan reported in log"
[ -f "$T/kb/tb/raw/beta.md" ] 2>/dev/null; [ -f "$T/kb/tk/raw/beta.md" ] && { PASS=$((PASS+1)); echo "  ok: orphan stays in raw/"; } || { FAIL=$((FAIL+1)); echo "  FAIL: orphan was moved"; }
[ ! -d "$T/kb/tk/raw/processed" ] && { PASS=$((PASS+1)); echo "  ok: no processed/ directory created"; } || { FAIL=$((FAIL+1)); echo "  FAIL: processed/ created"; }

# ── 4. Filenames with spaces ──────────────────────────────────────────────────
T=$(new_kb)
printf '# INBOX\n- Source: my file.md\n' > "$T/kb/tk/INBOX.md"
echo x > "$T/kb/tk/raw/my file.md"
echo y > "$T/kb/tk/raw/other file.md"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "files=2 referenced=1 orphans=1" "spaces in filenames handled"

# ── 5. Idempotent: repeated runs produce same classification ──────────────────
T=$(new_kb)
printf '# INBOX\n- Source: alpha.md\n' > "$T/kb/tk/INBOX.md"
echo a > "$T/kb/tk/raw/alpha.md"
echo b > "$T/kb/tk/raw/beta.md"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
N=$(grep -c "files=2 referenced=1 orphans=1" "$T/log.md")
[ "$N" -eq 2 ] && { PASS=$((PASS+1)); echo "  ok: second run classifies identically"; } || { FAIL=$((FAIL+1)); echo "  FAIL: second run differs ($N)"; }

# ── 6. RAG skip-on-unchanged + failure reported separately ────────────────────
T=$(new_kb)
mkdir -p "$T/scripts"
cat > "$T/scripts/rag-index.sh" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$T/scripts/rag-index.sh"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "RAG_INDEX .* FAILED" "rag failure logged separately"
if [ -f "$T/kb/tk/.rag-index-stamp" ]; then FAIL=$((FAIL+1)); echo "  FAIL: stamp written despite rag failure"; else PASS=$((PASS+1)); echo "  ok: no stamp on rag failure"; fi
# now a succeeding stub: first run indexes, second (unchanged wiki) skips
cat > "$T/scripts/rag-index.sh" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$T/scripts/rag-index.sh"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "re-indexed" "rag indexes when stamp missing"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "skipped (wiki unchanged" "rag skipped when wiki unchanged"
touch "$T/kb/tk/wiki/topics/new.md"
KBS_PATH="$T" KB_NAME=tk bash "$INGEST" >/dev/null 2>&1
expect_log "$T" "re-indexed" "rag re-indexes after wiki change"

# ── summary ───────────────────────────────────────────────────────────────────
echo
echo "test-hourly-ingest: $PASS passed, $FAIL failed"
rm -rf "${T:-/nonexistent}" 2>/dev/null
exit "$([ "$FAIL" -eq 0 ] && echo 0 || echo 1)"
