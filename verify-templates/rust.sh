#!/usr/bin/env bash
# .claude/verify.sh — quick check of a Rust project.
set -uo pipefail
cd "$(dirname "$0")/.." && cd "$(git rev-parse --show-toplevel)" || exit 1
OUT=$(mktemp)
cargo check --all-targets --quiet >"$OUT" 2>&1; RC=$?
[ $RC -eq 0 ] && { cargo test --quiet >>"$OUT" 2>&1; RC=$?; }
if [ $RC -ne 0 ]; then echo "verify FAIL (exit $RC)"; grep -E "^(error|warning: unused)" -A5 "$OUT" | head -n 40; rm -f "$OUT"; exit $RC; fi
rm -f "$OUT"; echo "verify OK"
