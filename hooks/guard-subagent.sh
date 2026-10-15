#!/usr/bin/env bash
# PreToolUse (Bash): hard denials for subagents — rules that a brief's text alone does not hold.
# Rule from the worker journal: an error class that repeated twice and can be caught by a command goes here.
# The main session (no agent_id) is not restricted.
set -uo pipefail
input=$(cat)
aid=$(jq -r '.agent_id // empty' <<<"$input")
[ -n "$aid" ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Workers have repeatedly shut down all simulators in the middle of other agents' runs.
if grep -qE '(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?(xcrun[[:space:]]+)?simctl[[:space:]]+(shutdown|erase)[[:space:]]+all' <<<"$cmd"; then
  deny "Subagents may not run simctl shutdown/erase all: other agents work in parallel. Shut down only your own UDID: xcrun simctl shutdown <UDID>."
fi
exit 0
