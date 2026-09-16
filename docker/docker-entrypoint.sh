#!/bin/bash
# KBS Docker entrypoint — seeds/refreshes the instance in the bind-mounted volume.
#
# Model (matches the native install's system/data separation):
#   SYSTEM  = this image (payload at /opt/kbs-system, built from the public repo)
#   DATA    = the bind-mounted directory (KBS_PATH, usually /root/kbs) — your private instance
#
# On every start:
#   - SYSTEM-OWNED files are refreshed from the image  (upgrade by rebuilding the image)
#   - USER-OWNED files are seeded only when absent     (never overwritten — no data loss)
set -e

SRC="${KBS_SYSTEM_SRC:-/opt/kbs-system}"   # payload baked into the image (override for tests)
DST="${KBS_PATH:-/root/kbs}"
KB_NAME="${KB_NAME:-main}"
VERSION="$(cat "$SRC/VERSION" 2>/dev/null || echo "unknown")"
TS="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p "$DST"
mkdir -p "$DST/kb/$KB_NAME"/{raw/chat-transcripts,raw-assets/{pdfs,images},wiki/{topics,snapshots},outputs}
mkdir -p "$DST/reference" "$DST/scripts/windows"

# ─── SYSTEM-OWNED: refresh from image on every start ─────────────────────────
for d in scripts reference; do
    if [ -d "$SRC/$d" ]; then
        mkdir -p "$DST/$d"
        cp -a "$SRC/$d/." "$DST/$d/"
    fi
done
for f in agents.md PROMPTS.md CHANGELOG.md VERSION; do
    [ -f "$SRC/$f" ] && cp -a "$SRC/$f" "$DST/$f"
done
chmod +x "$DST/scripts/"*.sh "$DST/scripts/"*.py 2>/dev/null || true

# ─── USER-OWNED: seed only if missing (never overwrite) ──────────────────────
for f in SYSTEM.md DECISIONS.md INBOX.md CHAT_INBOX.md FAILURES.md SUCCESSES.md \
         CAREER.md ACTIONS.md JOURNAL.md .gitignore; do
    if [ ! -e "$DST/$f" ] && [ -f "$SRC/$f" ]; then
        cp -a "$SRC/$f" "$DST/$f"
    fi
done
[ -d "$DST/examples" ] || { [ -d "$SRC/examples" ] && cp -a "$SRC/examples" "$DST/examples"; }

# log.md: generated (not copied) so the recorded path is the instance path
if [ ! -f "$DST/log.md" ]; then
    printf '# log\n' > "$DST/log.md"
    echo "## $TS | CONTAINER_INIT | V$VERSION | Path: $DST | KB: $KB_NAME" >> "$DST/log.md"
fi

# .env.template: always regenerated with the container's real paths
cat > "$DST/.env.template" <<EOF
# KBS V$VERSION — copy to .env and edit
KBS_PATH=$DST
KB_NAME=$KB_NAME
AUTO_INGEST=false
LLM_CLIENT=claude
ACTIVITY_LEVEL=0
EOF
[ -e "$DST/.env" ] || cp "$DST/.env.template" "$DST/.env"

echo "KBS V$VERSION — instance: $DST (KB: $KB_NAME)"
echo "  system files: refreshed from image"
echo "  data files:   preserved (seeded only when absent)"

exec "$@"
