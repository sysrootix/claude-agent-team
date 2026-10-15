#!/usr/bin/env bash
# .claude/verify.sh — quick check of a Python project.
set -uo pipefail
cd "$(dirname "$0")/.." && cd "$(git rev-parse --show-toplevel)" || exit 1
PY=${PY:-$( [ -x .venv/bin/python ] && echo .venv/bin/python || echo python3 )}
OUT=$(mktemp); RC=0
if command -v ruff >/dev/null; then ruff check . >"$OUT" 2>&1 || RC=$?; fi
[ $RC -eq 0 ] && { "$PY" -m pytest -q -x >>"$OUT" 2>&1 || RC=$?; }
if [ $RC -ne 0 ]; then echo "verify FAIL (exit $RC)"; tail -n 40 "$OUT"; rm -f "$OUT"; exit $RC; fi
rm -f "$OUT"; echo "verify OK"
