#!/bin/bash
# KBS YouTube Ingest — V0.116
# Downloads audio from a YouTube URL, extracts the transcript, and creates an INBOX
# entry pointing to the transcript.
#
# Transcript strategy: captions first (yt-dlp, fast, no Whisper), then Whisper/
# whisper.cpp on the downloaded audio as a fallback for videos without captions.
#
# Prerequisites: yt-dlp (required), whisper or whisper.cpp (optional — for auto-transcribe)
# Install yt-dlp: pip install yt-dlp  or  brew install yt-dlp
#
# Usage:
#   ~/kbs/scripts/youtube-ingest.sh "https://youtube.com/watch?v=..."
#   ~/kbs/scripts/youtube-ingest.sh "https://youtube.com/watch?v=..." "Extract key insights about metadata management"

set -e

KBS_PATH="${KBS_PATH:-$HOME/kbs}"
KB_NAME="${KB_NAME:-main}"
AUDIO_DIR="$KBS_PATH/kb/$KB_NAME/raw-assets/audio"
TRANSCRIPT_DIR="$KBS_PATH/kb/$KB_NAME/raw"
INBOX="$KBS_PATH/INBOX.md"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

URL="${1:-}"
INSTRUCTION="${2:-Extract key insights, timestamps, and any actionable advice.}"

if [ -z "$URL" ]; then
    echo "Usage: $0 <youtube-url> [extraction-instruction]"
    echo "Example: $0 'https://youtube.com/watch?v=...' 'Extract crawl strategy advice'"
    exit 1
fi

if ! command -v yt-dlp &>/dev/null; then
    echo -e "${RED}❌ yt-dlp not found.${NC}"
    echo "Install: pip install yt-dlp   or   brew install yt-dlp   or   apt install yt-dlp"
    exit 1
fi

mkdir -p "$AUDIO_DIR" "$TRANSCRIPT_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
DATE_STAMP=$(date '+%Y-%m-%d')

# ─── Download audio ───────────────────────────────────────────────────────────
echo -e "${YELLOW}⬇️  Downloading audio...${NC}"
TITLE=$(yt-dlp --print title "$URL" 2>/dev/null || echo "youtube-$DATE_STAMP")
SAFE_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')
AUDIO_FILE="$AUDIO_DIR/${SAFE_TITLE}.m4a"

yt-dlp -f "bestaudio[ext=m4a]/bestaudio" --extract-audio --audio-format m4a \
    -o "$AUDIO_FILE" "$URL" --no-playlist --quiet

echo -e "${GREEN}✅ Audio saved: $AUDIO_FILE${NC}"

# ─── Transcribe (best effort) ─────────────────────────────────────────────────
TRANSCRIPT_FILE="$TRANSCRIPT_DIR/${SAFE_TITLE}-transcript.txt"

# Try captions first (fast, no Whisper) — manual subs preferred, auto-generated as fallback.
CAPTIONS_DIR="$TRANSCRIPT_DIR/captions-tmp"
mkdir -p "$CAPTIONS_DIR"
if [ ! -f "$TRANSCRIPT_FILE" ]; then
    echo -e "${YELLOW}📝 Fetching captions (yt-dlp)...${NC}"
    yt-dlp --skip-download --write-subs --write-auto-subs \
        --sub-langs "en.*,en" --sub-format vtt \
        --convert-subs vtt -o "$CAPTIONS_DIR/%(id)s" "$URL" --no-playlist --quiet 2>/dev/null || true
    VTT_FILE="$(find "$CAPTIONS_DIR" -name '*.vtt' 2>/dev/null | head -1)"
    if [ -n "$VTT_FILE" ] && [ -f "$VTT_FILE" ]; then
        # Strip VTT timing/tags and dedupe consecutive lines into plain text.
        python3 - "$VTT_FILE" "$TRANSCRIPT_FILE" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
lines, seen = [], set()
for raw in open(src, encoding="utf-8", errors="replace"):
    l = raw.strip()
    if not l or l == "WEBVTT" or "-->" in l or l.isdigit() or l.startswith(("Kind:", "Language:")):
        continue
    l = re.sub(r"<[^>]+>", "", l)
    l = re.sub(r"\s+", " ", l).strip()
    if l and l not in seen:
        seen.add(l); lines.append(l)
open(dst, "w", encoding="utf-8").write("\n".join(lines))
PY
        rm -rf "$CAPTIONS_DIR"
        [ -s "$TRANSCRIPT_FILE" ] && echo -e "${GREEN}✅ Captions saved (no transcription needed)${NC}" || rm -f "$TRANSCRIPT_FILE"
    fi
fi

if [ ! -f "$TRANSCRIPT_FILE" ] && command -v whisper &>/dev/null; then
    echo -e "${YELLOW}📝 Transcribing with whisper...${NC}"
    whisper "$AUDIO_FILE" --model small --language English --output_format txt --output_dir "$TRANSCRIPT_DIR" --fp16 False 2>/dev/null || true
    # whisper outputs to same dir as input by default; move/rename if needed
    WHISPER_OUT="$(dirname "$AUDIO_FILE")/$(basename "$AUDIO_FILE" .m4a).txt"
    if [ -f "$WHISPER_OUT" ]; then
        mv "$WHISPER_OUT" "$TRANSCRIPT_FILE"
    fi
elif [ ! -f "$TRANSCRIPT_FILE" ] && { command -v whisper.cpp &>/dev/null || [ -f "$HOME/whisper.cpp/main" ]; }; then
    echo -e "${YELLOW}📝 Transcribing with whisper.cpp...${NC}"
    WAV_FILE="${AUDIO_FILE%.m4a}.wav"
    ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV_FILE" -y 2>/dev/null || true
    WHISPER_MODEL="${WHISPER_MODEL:-$HOME/whisper.cpp/models/ggml-small.bin}"
    if [ -f "$HOME/whisper.cpp/main" ] && [ -f "$WHISPER_MODEL" ]; then
        "$HOME/whisper.cpp/main" -m "$WHISPER_MODEL" -f "$WAV_FILE" -otxt -of "${TRANSCRIPT_FILE%.txt}" 2>/dev/null || true
    fi
    rm -f "$WAV_FILE"
else
    [ ! -f "$TRANSCRIPT_FILE" ] && {
        echo -e "${YELLOW}⚠️  No captions and no whisper found. Audio saved; transcribe manually.${NC}"
        echo "Install: pip install openai-whisper   or   build whisper.cpp"
    }
fi

# ─── Create INBOX entry ───────────────────────────────────────────────────────
if [ -f "$TRANSCRIPT_FILE" ]; then
    echo -e "${GREEN}✅ Transcript saved: $TRANSCRIPT_FILE${NC}"
    REF_FILE="raw/$(basename "$TRANSCRIPT_FILE")"
else
    TRANSCRIPT_FILE="$AUDIO_FILE"
    REF_FILE="raw-assets/audio/$(basename "$AUDIO_FILE")"
    echo -e "${YELLOW}⚠️  No transcript yet. INBOX points to audio file.${NC}"
fi

{
    echo ""
    echo "### $TIMESTAMP"
    echo "TXT: $(basename "$TRANSCRIPT_FILE") — $INSTRUCTION"
    echo "Source: $URL"
    echo "Title: $TITLE"
} >> "$INBOX"

echo -e "${GREEN}✅ INBOX entry created.${NC}"
echo "Next: Follow agents.md. Ingest $KB_NAME"
