#!/usr/bin/env bash
# .claude/verify.sh — quick check of a Go project.
set -uo pipefail
cd "$(dirname "$0")/.." && cd "$(git rev-parse --show-toplevel)" || exit 1
OUT=$(mktemp)
{ go vet ./... && go test ./... ; } >"$OUT" 2>&1; RC=$?
if [ $RC -ne 0 ]; then echo "verify FAIL (exit $RC)"; tail -n 40 "$OUT"; rm -f "$OUT"; exit $RC; fi
rm -f "$OUT"; echo "verify OK"
