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

PROJECT="${1:?usage: graphify-index.sh <project> <code_dir> [--deep] [--wiki]}"
CODE_DIR="${2:?usage: graphify-index.sh <project> <code_dir> [--deep] [--wiki]}"
MODE="standard"
WIKI=0
for a in "${@:3}"; do
  case "$a" in
    --deep|--mode\ deep) MODE="deep" ;;
    --wiki) WIKI=1 ;;
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

# Build the graph (deterministic AST). graphify writes into <cwd>/graphify-out
# when given a bare path, so run from $WORK on ./corpus so output lands in $WORK.
echo "--- extract ---"
WRAP_G="$(cd "$WORK" && "$GRAPHIFY" ./corpus --mode "$MODE" 2>&1 || true)"

GRAW="$WORK/corpus/graphify-out"
if [ ! -f "$GRAW/graph.json" ]; then
  echo "--- extract (plain) ---"
  (cd "$WORK" && "$GRAPHIFY" ./corpus 2>&1 || true)
fi

if [ ! -f "$GRAW/graph.json" ]; then
  echo "WARN: graphify produced no graph.json; dumping output:" >&2
  echo "${WRAP_G}" | tail -n 20 >&2
  exit 3
fi

# Copy the graph artifacts into the project.
cp "$GRAW/graph.json" "$GRAPHS_DIR/graph.json"
[ -f "$GRAW/graph.html" ] && cp "$GRAW/graph.html" "$GRAPHS_DIR/graph.html" 2>/dev/null || true
[ -f "$GRAW/.graphify_labels.json" ] && cp "$GRAW/.graphify_labels.json" "$GRAPHS_DIR/labels.json" 2>/dev/null || true
[ -f "$GRAW/.graphify_analysis.json" ] && cp "$GRAW/.graphify_analysis.json" "$GRAPHS_DIR/analysis.json" 2>/dev/null || true

# Build the report (community labeling needs claude -p; degrades gracefully).
echo "--- report ---"
(cd "$WORK/corpus" && "$GRAPHIFY" cluster-only ./ 2>&1 | tail -n 4 || \
 "$GRAPHIFY" cluster-only . 2>&1 | tail -n 4 || \
 true)
[ -f "$GRAW/GRAPH_REPORT.md" ] && cp "$GRAW/GRAPH_REPORT.md" "$GRAPHS_DIR/GRAPH_REPORT.md" 2>/dev/null || true

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
