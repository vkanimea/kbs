#!/bin/bash
# graphify-index.sh — KBS Graphify knowledge-graph indexer (V0.116)
#
# Turns a code corpus into a queryable knowledge graph + agent-crawlable wiki,
# stored inside the per-project KBS layout (kb/projects/<project>/...).
# This is the Pattern-A "acquire/structure" primitive: deterministic AST parsing
# (tree-sitter) builds the graph locally — no LLM, no vector store. Doc/image
# extraction and community naming need a wired LLM CLI (claude -p) and degrade
# gracefully to placeholders/code-only when absent.
#
# Usage:
#   graphify-index.sh <project> <code_dir> [--deep] [--wiki]
# Examples:
#   graphify-index.sh pi-jev ~/pi-jev/src --wiki
#
# Output layout:
#   kb/projects/<project>/graphs/graph.json        (persistent, queryable)
#   kb/projects/<project>/graphs/GRAPH_REPORT.md
#   kb/projects/<project>/graphs/graph.html
#   kb/projects/<project>/wiki/graph/<file>.md     (when --wiki)
#   kb/projects/<project>/wiki/graph/index.md      (agent entry point, when --wiki)

set -euo pipefail

KBS="${KBS:-$HOME/kbs}"
GRAPHIFY="${GRAPHIFY:-$HOME/.local/bin/graphify}"
# Local semantic backend (for --local): the llama.cpp OpenAI-compatible server on
# localhost; infer a key from the process if our env file is not sourced.
LOCAL_PORT="${LOCAL_PORT:-8080}"
LOCAL_MODEL="${LOCAL_MODEL:-qwen2.5-coder-1.5b-instruct-q4_k_m}"
LOCAL_KEY="${LOCAL_KEY:-local}"
if [ "${OPENAI_BASE_URL:-}" = "" ]; then
  export OPENAI_BASE_URL="http://127.0.0.1:${LOCAL_PORT}/v1"
fi
if [ "${OPENAI_API_KEY:-}" = "" ]; then
  export OPENAI_API_KEY="$LOCAL_KEY"
fi

PROJECT="${1:?usage: graphify-index.sh <project> <code_dir> [--deep] [--wiki] [--backend B] [--local] [--openrouter] [--model M]}"
CODE_DIR="${2:?usage: graphify-index.sh <project> <code_dir> [--deep] [--wiki] [--backend B] [--local] [--openrouter] [--model M]}"
MODE="deep"        # graphify (>=0.9) only accepts 'deep'; 'standard' is not a valid mode
WIKI=0
BACKEND=""          # empty => auto: code-only if no key, else semantic via configured key
LOCAL_BACKEND=0
OPENROUTER_BACKEND=0
OPENROUTER_MODEL=""
for a in "${@:3}"; do
  case "$a" in
    --deep|--mode\ deep) MODE="deep" ;;
    --wiki) WIKI=1 ;;
    --local) LOCAL_BACKEND=1 ;;
    --openrouter) OPENROUTER_BACKEND=1 ;;
    --model\ *) OPENROUTER_MODEL="${a#--model }" ;;
    --model=*) OPENROUTER_MODEL="${a#--model=}" ;;
    --backend\ *) BACKEND="${a#--backend }" ;;
    --backend=*) BACKEND="${a#--backend=}" ;;
  esac
done

[ -x "$GRAPHIFY" ] || { echo "ERROR: graphify not found at $GRAPHIFY. Install: pip install --user graphifyy" >&2; exit 2; }
[ -d "$CODE_DIR" ] || { echo "ERROR: code dir not found: $CODE_DIR" >&2; exit 2; }

PROJ_ROOT="$KBS/kb/projects/$PROJECT"
GRAPHS_DIR="$PROJ_ROOT/graphs"
WIKI_DIR="$PROJ_ROOT/wiki/graph"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stage a shallow copy of just the code (skip vcs, built deps, giant dirs) so
# graphify indexes only real source. Uses full paths so cross-file refs survive.
mkdir -p "$WORK/corpus"
if [ -f "$CODE_DIR/package.json" ]; then
  cp "$CODE_DIR/package.json" "$WORK/corpus/" 2>/dev/null || true
fi
# rsync filtering; fall back to cp if rsync missing
if command -v rsync >/dev/null 2>&1; then
  rsync -a --quiet \
    --exclude '.git' --exclude 'node_modules' --exclude 'venv' --exclude '.venv' \
    --exclude 'dist' --exclude 'build' --exclude '__pycache__' \
    --exclude '*.lock' --exclude '.next' --exclude 'coverage' \
    "$CODE_DIR"/ "$WORK/corpus/" 2>/dev/null || true
else
  cp -r "$CODE_DIR"/ "$WORK/corpus/" 2>/dev/null || true
fi

[ -n "$(ls -A "$WORK/corpus" 2>/dev/null)" ] || { echo "ERROR: nothing staged from $CODE_DIR" >&2; exit 2; }

echo "=== graphify-index: project=$PROJECT mode=$MODE wiki=$WIKI ==="
mkdir -p "$GRAPHS_DIR" "$WIKI_DIR"

# Build the graph. --backend / --local force semantic doc extraction (so project
# documentation gets graphed); otherwise default: deterministic AST (--code-only)
# for code if no LLM key is configured, or semantic via the configured key.
echo "--- extract ---"
GRAW="$WORK/corpus/graphify-out"
EXTRACT_ARGS=()
if [ "$OPENROUTER_BACKEND" = "1" ] || [ "$BACKEND" = "openrouter" ]; then
  # Use the OpenRouter key pi already holds (goal-loop) to reach DeepSeek models.
  # graphify prefers --backend openai + OPENAI_BASE_URL for OpenAI-compatible gateways.
  OR_KEY=""
  for cand in "${OPENROUTER_API_KEY:-}" "$(timeout 15 "${PI_BIN:-pi}" auth print-api-key --provider openrouter 2>/dev/null | head -n1)"; do
    if [ -n "$cand" ]; then OR_KEY="$cand"; break; fi
  done
  if [ -z "$OR_KEY" ]; then
    echo "ERROR: --openrouter requested but no OpenRouter key found (checked OPENROUTER_API_KEY and pi auth)" >&2
    exit 2
  fi
  export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
  export OPENAI_API_KEY="$OR_KEY"
  EXTRACT_ARGS=(--backend openai)
  # Model is model-agnostic: --model wins, else $OPENROUTER_MODEL, else the
  # instance's configured PI_MODEL (model.conf) so we never bake in a vendor.
  if [ -z "$OPENROUTER_MODEL" ]; then
    _mcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$_mcdir/model-config.sh" ]; then
      # shellcheck source=scripts/model-config.sh
      . "$_mcdir/model-config.sh"
      kbs_resolve_model --quiet 2>/dev/null && OPENROUTER_MODEL="$PI_MODEL"
    fi
  fi
  [ -n "$OPENROUTER_MODEL" ] && EXTRACT_ARGS+=(--model "$OPENROUTER_MODEL")
  echo "(semantic extraction via OpenRouter -> ${OPENROUTER_MODEL:-provider default})"
elif [ -n "$BACKEND" ] && [ "$BACKEND" != "local" ]; then
  # Explicit cloud backend (e.g. deepseek) -> semantic extraction of docs + code.
  EXTRACT_ARGS=(--backend "$BACKEND")
  echo "(semantic extraction via --backend $BACKEND)"
elif [ "$LOCAL_BACKEND" = "1" ] || [ "$BACKEND" = "local" ]; then
  # Local llama.cpp (OpenAI-compatible) backend for private/free doc indexing.
  EXTRACT_ARGS=(--backend openai --model "$LOCAL_MODEL")
  echo "(local doc extraction via llama.cpp:$LOCAL_PORT / $LOCAL_MODEL)"
elif [ -z "${GEMINI_API_KEY:-}${GOOGLE_API_KEY:-}${MOONSHOT_API_KEY:-}${ANTHROPIC_API_KEY:-}${OPENAI_API_KEY:-}${DEEPSEEK_API_KEY:-}" ]; then
  # No LLM key -> deterministic AST (code-only). Docs are skipped (no llm).
  EXTRACT_ARGS+=(--code-only)
  echo "(no LLM key: code-only AST index)"
else
  echo "(semantic extraction using a configured *_API_KEY)"
fi
WRAP_G="$(cd "$WORK" && "$GRAPHIFY" ./corpus --mode "$MODE" "${EXTRACT_ARGS[@]}" 2>&1 || true)"
if [ ! -f "$GRAW/graph.json" ]; then
  # Could not build a graph; dump the output for diagnosis.
  echo "WARN: graphify produced no graph.json; dumping output:" >&2
  echo "${WRAP_G}" | tail -n 20 >&2
  exit 3
fi

# Copy the graph artifacts into the project (graph files exist post-extract).
cp "$GRAW/graph.json" "$GRAPHS_DIR/graph.json"
[ -f "$GRAW/.graphify_labels.json" ] && cp "$GRAW/.graphify_labels.json" "$GRAPHS_DIR/labels.json" 2>/dev/null || true
[ -f "$GRAW/.graphify_analysis.json" ] && cp "$GRAW/.graphify_analysis.json" "$GRAPHS_DIR/analysis.json" 2>/dev/null || true

# Build the report + interactive HTML graph (community labeling needs claude -p;
# degrades gracefully). cluster-only emits GRAPH_REPORT.md AND graph.html into the
# work corpus dir, so copy BOTH here (after it runs) — copying graph.html before
# this step would miss it.
echo "--- report ---"
(cd "$WORK/corpus" && "$GRAPHIFY" cluster-only ./ 2>&1 | tail -n 4 || \
 "$GRAPHIFY" cluster-only . 2>&1 | tail -n 4 || \
 true)
[ -f "$GRAW/GRAPH_REPORT.md" ] && cp "$GRAW/GRAPH_REPORT.md" "$GRAPHS_DIR/GRAPH_REPORT.md" 2>/dev/null || true
[ -f "$GRAW/graph.html" ] && cp "$GRAW/graph.html" "$GRAPHS_DIR/graph.html" 2>/dev/null || true

# Optional wiki export (agent-crawlable markdown entry point).
if [ "$WIKI" = "1" ]; then
  echo "--- wiki export ---"
  (cd "$WORK/corpus" && "$GRAPHIFY" export wiki --graph ./graphify-out/graph.json 2>&1 | tail -n 3 || true)
  if [ -d "$GRAW/wiki" ]; then
    rm -rf "$WIKI_DIR"; mkdir -p "$WIKI_DIR"
    cp "$GRAW/wiki/"*.md "$WIKI_DIR/" 2>/dev/null || true
    echo "wiki: $(ls "$WIKI_DIR"/*.md 2>/dev/null | wc -l) articles -> $WIKI_DIR"
  fi
fi

echo
echo "=== DONE ==="
echo "graph   : $GRAPHS_DIR/graph.json"
echo "report  : $GRAPHS_DIR/GRAPH_REPORT.md"
echo "wiki    : $WIKI_DIR/"
echo
# Quick stats from the graph
"$GRAPHIFY" --version >/dev/null 2>&1
python3 - "$GRAPHS_DIR/graph.json" <<'PY' 2>/dev/null || true
import sys, json
try:
    d = json.load(open(sys.argv[1]))
    n = len(d.get('nodes', d.get('graph', {}).get('nodes', [])))
    e = len(d.get('edges', d.get('graph', {}).get('edges', [])))
    print(f"graph: {n} nodes, {e} edges")
except Exception as ex:
    print(f"(graph stats unavailable: {ex})")
PY
