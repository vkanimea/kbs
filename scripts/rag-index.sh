#!/bin/bash
# KBS — rebuild the semantic index over wiki/topics/ (see scripts/rag.py)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/rag.py" index
