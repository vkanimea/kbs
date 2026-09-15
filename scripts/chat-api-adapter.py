#!/usr/bin/env python3
"""
KBS Universal Chat API Adapter — V0.114

Captures chat output from any LLM API via webhook or stdin.

Supports:
  - Claude API format
  - ChatGPT/OpenAI API format
  - Gemini API format
  - Generic JSON or plain text

Usage:
  # As webhook server (receives POST requests)
  python3 chat-api-adapter.py --server --port 8080

  # From a file
  python3 chat-api-adapter.py --file transcript.txt

  # From text argument
  python3 chat-api-adapter.py --text "Your chat text"

  # From stdin (pipe)
  echo "chat text" | python3 chat-api-adapter.py

  # Send webhook from another terminal
  curl -X POST http://localhost:8080/capture \\
    -H "Content-Type: application/json" \\
    -d '{"content": "Chat text here", "model": "claude"}'
"""

import json
import sys
import os
import argparse
from datetime import datetime
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler

# ─── Configuration ─────────────────────────────────────────────────────────────
KBS_PATH     = Path(os.environ.get("KBS_PATH", Path.home() / "kbs"))
KB_NAME      = os.environ.get("KB_NAME", "main")
CHAT_INBOX   = Path(os.environ.get("CHAT_INBOX", KBS_PATH / "CHAT_INBOX.md"))
CHAT_RAW_DIR = Path(os.environ.get("CHAT_RAW_DIR", KBS_PATH / "kb" / KB_NAME / "raw" / "chat-transcripts"))
AUTO_INGEST  = os.environ.get("AUTO_INGEST", "false").lower() == "true"


def ensure_dirs():
    CHAT_INBOX.parent.mkdir(parents=True, exist_ok=True)
    CHAT_RAW_DIR.mkdir(parents=True, exist_ok=True)


# ─── LLM Detection ─────────────────────────────────────────────────────────────
def detect_llm(payload: dict | str) -> str:
    text = json.dumps(payload).lower() if isinstance(payload, dict) else str(payload).lower()
    if "claude" in text or "anthropic" in text:
        return "Claude"
    elif "chatgpt" in text or "gpt-4" in text or "openai" in text:
        return "ChatGPT"
    elif "gemini" in text or "bard" in text:
        return "Gemini"
    elif "llama" in text:
        return "Llama (local)"
    elif "mistral" in text:
        return "Mistral (local)"
    else:
        return "Unknown LLM"


# ─── Content Extraction ────────────────────────────────────────────────────────
def extract_content(payload: dict | str) -> str:
    if isinstance(payload, str):
        return payload
    # Claude API
    if "content" in payload:
        c = payload["content"]
        if isinstance(c, list):
            return " ".join(b.get("text", "") for b in c if b.get("type") == "text")
        return str(c)
    # OpenAI API
    if "choices" in payload and payload["choices"]:
        return payload["choices"][0].get("message", {}).get("content", "")
    # Gemini API
    if "candidates" in payload and payload["candidates"]:
        return payload["candidates"][0].get("content", {}).get("parts", [{}])[0].get("text", "")
    # Generic
    for key in ("text", "message", "response", "output", "result"):
        if key in payload:
            return str(payload[key])
    return json.dumps(payload)


def extract_title(content: str) -> str:
    first = content.split("\n")[0].strip().lstrip("#").strip()
    return (first[:60] + "…") if len(first) > 60 else first or "Chat capture"


# ─── Write to CHAT_INBOX.md ────────────────────────────────────────────────────
def write_to_inbox(content: str, llm_name: str, source: str, raw_filename: str) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    title = extract_title(content)
    preview_lines = content.split("\n")[:20]

    with open(CHAT_INBOX, "a", encoding="utf-8") as f:
        f.write(f"\n## {timestamp} | Conversation with {llm_name}\n")
        f.write(f"**Source:** {source}\n")
        f.write(f"**Topic:** {title}\n")
        f.write(f"**Confidence:** LOW (awaiting verification)\n\n")
        f.write("### Key Insights\n")
        for line in preview_lines:
            if line.strip():
                f.write(f"- {line.strip()}\n")
        f.write("\n### Action Items\n")
        f.write("- [ ] Verify insights with primary sources before adding to wiki\n\n")
        f.write("### Contradictions with Existing Wiki\n")
        f.write("- _Pending — checked during ingestion_\n\n")
        f.write("### Raw Transcript\n")
        f.write(f"raw/chat-transcripts/{raw_filename}\n")


def save_raw_transcript(content: str, llm_name: str, source: str) -> str:
    ts = datetime.now()
    date_s = ts.strftime("%Y-%m-%d")
    time_s = ts.strftime("%H%M%S")
    safe_name = llm_name.replace(" ", "-").replace("(", "").replace(")", "")
    filename = f"chat-{date_s}-{time_s}-{safe_name}.md"
    filepath = CHAT_RAW_DIR / filename

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(f"# Chat with {llm_name}\n")
        f.write(f"**Date:** {ts.strftime('%Y-%m-%d %H:%M')}\n")
        f.write(f"**Source:** {source}\n\n---\n\n")
        f.write(content)

    return filename


def capture(payload: dict | str, source: str = "API") -> bool:
    ensure_dirs()
    content  = extract_content(payload)
    llm_name = detect_llm(payload)
    filename = save_raw_transcript(content, llm_name, source)
    write_to_inbox(content, llm_name, source, filename)
    print(f"✅ Captured to CHAT_INBOX.md  |  LLM: {llm_name}  |  Raw: {CHAT_RAW_DIR / filename}")
    if AUTO_INGEST:
        print("🔄 AUTO_INGEST=true — run in LLM client: Follow agents.md. Process CHAT_INBOX.md.")
    else:
        print("Next: Follow agents.md. Process CHAT_INBOX.md.")
    return True


# ─── HTTP Webhook Server ───────────────────────────────────────────────────────
class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length)
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            payload = {"text": body.decode("utf-8", errors="replace")}

        capture(payload, "API webhook")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"status": "ok", "message": "Captured"}).encode())

    def log_message(self, fmt, *args):
        pass  # Suppress default access log


def run_server(port: int = 8080):
    print(f"KBS Chat API Adapter — listening on port {port}")
    print(f"POST to: http://localhost:{port}/capture")
    print("Send: curl -X POST http://localhost:{port}/capture -H 'Content-Type: application/json' -d '{{\"text\":\"chat text\"}}'")
    print("Press Ctrl+C to stop.")
    HTTPServer(("localhost", port), WebhookHandler).serve_forever()


# ─── Entry Point ───────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="KBS Chat API Adapter V0.114")
    parser.add_argument("--server", action="store_true", help="Run as HTTP webhook server")
    parser.add_argument("--port",   type=int, default=8080, help="Webhook server port")
    parser.add_argument("--file",   type=str, help="Path to transcript file")
    parser.add_argument("--text",   type=str, help="Direct text input")
    args = parser.parse_args()

    if args.server:
        run_server(args.port)
    elif args.file:
        with open(args.file, "r", encoding="utf-8") as f:
            capture({"text": f.read()}, f"file:{args.file}")
    elif args.text:
        capture({"text": args.text}, "argument")
    elif not sys.stdin.isatty():
        data = sys.stdin.read()
        try:
            payload = json.loads(data)
        except json.JSONDecodeError:
            payload = {"text": data}
        capture(payload, "stdin")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
