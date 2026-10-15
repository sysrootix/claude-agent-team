#!/usr/bin/env bash
# Stop / SubagentStop: before "done", runs .claude/verify.sh of every repository
# this agent edited in the session. Red verify -> exit 2, the agent continues and fixes it.
set -uo pipefail
input=$(cat)
sid=$(jq -r '.session_id // "nosession"' <<<"$input")
aid=$(jq -r '.agent_id // "main"' <<<"$input")
active=$(jq -r '.stop_hook_active // false' <<<"$input")
st="$HOME/.claude/hooks/state/${sid}_${aid}.repos"
[ -s "$st" ] || exit 0

failed=0; report=""
while IFS= read -r root; do
  [ -x "$root/.claude/verify.sh" ] || continue
  # nothing to check if the repo has no uncommitted changes
  [ -n "$(git -C "$root" status --porcelain 2>/dev/null | head -1)" ] || continue
  out=$(cd "$root" && perl -e 'alarm shift; exec @ARGV' 240 ./.claude/verify.sh 2>&1); rc=$?
  if [ $rc -ne 0 ]; then
    failed=1
    [ $rc -eq 142 ] && out="verify.sh did not finish within 240 s"
    report+=$'\n'"== $root (.claude/verify.sh, code $rc)"$'\n'"$(tail -40 <<<"$out")"
  fi
done <"$st"

if [ $failed -eq 0 ]; then rm -f "$st"; exit 0; fi
# Second run in a row — do not loop: let it through, but leave a trace for the orchestrator.
if [ "$active" = "true" ]; then
  echo "verify is still red — report this in your summary (status: partial).$report" >&2
  rm -f "$st"; exit 0
fi
echo "Project check failed — fix the errors before reporting:$report" >&2
exit 2
