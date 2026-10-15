#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): quick syntax check of the edited file
# + remembers the repository so verify-on-stop.sh can run its .claude/verify.sh.
set -uo pipefail
input=$(cat)
f=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -n "$f" ] && [ -f "$f" ] || exit 0
sid=$(jq -r '.session_id // "nosession"' <<<"$input")
aid=$(jq -r '.agent_id // "main"' <<<"$input")

root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$root" ] && [ -x "$root/.claude/verify.sh" ]; then
  st="$HOME/.claude/hooks/state/${sid}_${aid}.repos"
  grep -qxF "$root" "$st" 2>/dev/null || echo "$root" >>"$st"
fi

err=""
base=$(basename "$f")
case "$f" in
  *.json)
    case "$base" in tsconfig*|jsconfig*|*.jsonc) ;; *)
      err=$(python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>&1 | tail -1) ;;
    esac ;;
  *.sh|*.bash) err=$(bash -n "$f" 2>&1) ;;
  *.py) err=$(python3 -m py_compile "$f" 2>&1 | tail -5) ;;
  *.php) command -v php >/dev/null && { out=$(php -l "$f" 2>&1) || err="$out"; } ;;
  *.rb) command -v ruby >/dev/null && err=$(ruby -c "$f" 2>&1 >/dev/null) ;;
esac
if [ -n "$err" ]; then
  echo "Syntax error in $f:" >&2
  echo "$err" >&2
  exit 2
fi
exit 0
