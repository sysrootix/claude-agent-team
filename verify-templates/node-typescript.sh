#!/usr/bin/env bash
# .claude/verify.sh — quick check of a TS project: type check only (+ tests if they are fast).
set -uo pipefail
cd "$(dirname "$0")/.." && cd "$(git rev-parse --show-toplevel)" || exit 1
TSC=./node_modules/.bin/tsc
[ -x "$TSC" ] || { echo "verify: $TSC not found — run npm install"; exit 1; }
OUT=$(mktemp)
"$TSC" --noEmit >"$OUT" 2>&1; RC=$?
# If the project has fast tests, uncomment:
# [ $RC -eq 0 ] && { npm test --silent >>"$OUT" 2>&1; RC=$?; }
if [ $RC -ne 0 ]; then echo "verify FAIL (exit $RC)"; head -n 40 "$OUT"; rm -f "$OUT"; exit $RC; fi
rm -f "$OUT"; echo "verify OK"
