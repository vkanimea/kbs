#!/usr/bin/env python3
"""
KBS RAG — semantic retrieval over wiki/topics/ (Option 1: minimal local).

Subcommands:
  index            Rebuild the vector index from wiki/topics/*.md
  query "text" [k] Embed query, return top-k topics (default k=5)
  status           Show index stats

Components (all local):
  chunker : whole topic page = one vector
  embedder: Ollama (default model nomic-embed-text)
  store   : JSON file at kb/<name>/rag-index/index.json (git-ignored, regenerable)
  search  : cosine similarity in stdlib

Env:
  KBS_PATH         default ~/kbs
  KB_NAME          default main
  KBS_RAG_MODEL    default nomic-embed-text
  OLLAMA_HOST      default http://127.0.0.1:11434
"""
import json, math, os, sys, urllib.request

KBS_PATH = os.environ.get("KBS_PATH", os.path.expanduser("~/kbs"))
KB_NAME = os.environ.get("KB_NAME", "main")
MODEL = os.environ.get("KBS_RAG_MODEL", "nomic-embed-text")
OLLAMA = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434").rstrip("/")
TOPICS_DIR = os.path.join(KBS_PATH, "kb", KB_NAME, "wiki", "topics")
INDEX_DIR = os.path.join(KBS_PATH, "kb", KB_NAME, "rag-index")
INDEX_FILE = os.path.join(INDEX_DIR, "index.json")

def link_name(fname):
    return os.path.splitext(os.path.basename(fname))[0]

def ollama_embed(text):
    req = urllib.request.Request(
        OLLAMA + "/api/embed",
        data=json.dumps({"model": MODEL, "input": text}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            data = json.loads(r.read())
        return data["embeddings"][0]
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"Model '{MODEL}' not found. Run: ollama pull {MODEL}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Ollama unreachable at {OLLAMA}: {e.reason}. Is 'ollama serve' running?", file=sys.stderr)
        sys.exit(1)

def cmd_index():
    files = sorted(f for f in os.listdir(TOPICS_DIR) if f.endswith(".md"))
    if not files:
        print(f"No topic files found in {TOPICS_DIR}", file=sys.stderr)
        sys.exit(1)
    docs = []
    for i, f in enumerate(files, 1):
        path = os.path.join(TOPICS_DIR, f)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        vec = ollama_embed(f"[[{link_name(f)}]]\n{text}")
        docs.append({"name": link_name(f), "path": os.path.relpath(path), "vector": vec, "chars": len(text)})
        print(f"[{i}/{len(files)}] embedded [[{link_name(f)}]]", file=sys.stderr)
    os.makedirs(INDEX_DIR, exist_ok=True)
    with open(INDEX_FILE, "w", encoding="utf-8") as fh:
        json.dump({"model": MODEL, "docs": docs}, fh)
    print(f"Indexed {len(docs)} topics → {INDEX_FILE}")

def cosine(a, b):
    dot = sum(x*y for x, y in zip(a, b))
    na = math.sqrt(sum(x*x for x in a))
    nb = math.sqrt(sum(y*y for y in b))
    return dot / (na * nb) if na and nb else 0.0

def cmd_status():
    if not os.path.exists(INDEX_FILE):
        print("No index — run: rag-index.sh")
        return
    with open(INDEX_FILE, encoding="utf-8") as fh:
        data = json.load(fh)
    print(f"model : {data['model']}")
    print(f"topics: {len(data['docs'])}")
    print(f"file  : {INDEX_FILE}")

def cmd_query(args):
    if not args:
        print("usage: rag.py query \"search text\" [k]", file=sys.stderr)
        sys.exit(2)
    text = args[0]
    k = int(args[1]) if len(args) > 1 else 5
    if not os.path.exists(INDEX_FILE):
        print("No index — run: rag-index.sh", file=sys.stderr)
        sys.exit(1)
    with open(INDEX_FILE, encoding="utf-8") as fh:
        data = json.load(fh)
    qvec = ollama_embed(text)
    scored = []
    for d in data["docs"]:
        scored.append((cosine(qvec, d["vector"]), d))
    scored.sort(key=lambda s: -s[0])
    for rank, (score, d) in enumerate(scored[:k], 1):
        snippet_path = os.path.join(KBS_PATH, d["path"])
        try:
            with open(snippet_path, encoding="utf-8") as fh:
                first = next((l.strip() for l in fh if l.strip() and not l.startswith("#")), "")[:90]
        except OSError:
            first = ""
        print(f"{rank}. [[{d['name']}]]  {score:.3f}  {first}")
    return scored[:k]

def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("index", "query", "status"):
        print(__doc__)
        sys.exit(2)
    sub = sys.argv[1]
    if sub == "index": cmd_index()
    elif sub == "status": cmd_status()
    else: cmd_query(sys.argv[2:])

main()
