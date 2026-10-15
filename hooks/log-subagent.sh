#!/usr/bin/env bash
# SubagentStop: one JSONL line per finished worker/reviewer run → ~/.claude/worker-runs.jsonl.
# Summary: ~/.claude/bin/worker-stats. Blocks nothing, always exits 0.
set -uo pipefail
input=$(cat)
type=$(jq -r '.agent_type // empty' <<<"$input")
case "$type" in worker-*|reviewer*) ;; *) exit 0 ;; esac
tr=$(jq -r '.agent_transcript_path // empty' <<<"$input")
tr="${tr/#\~/$HOME}"
msg=$(jq -r '.last_assistant_message // ""' <<<"$input")

# Worker status / reviewer verdict — from the first lines of the report.
# Russian report keywords are kept next to the English ones (status: / verdict:).
head=$(head -c 1500 <<<"$msg" | tr '[:upper:]' '[:lower:]')
outcome=other
case "$head" in
  *"вернуть воркеру"*|*"return to worker"*) outcome=return ;;
  *"нужен оркестратор"*|*"needs orchestrator"*) outcome=orchestrator ;;
  *"вердикт:"*принять*|*"вердикт**:"*принять*|*"verdict:"*accept*|*"verdict**:"*accept*) outcome=accept ;;
  *"статус:"*частично*|*"статус**:"*частично*|*"status:"*partial*|*"status**:"*partial*) outcome=partial ;;
  *"статус:"*остановлен*|*"статус**:"*остановлен*|*"status:"*stopped*|*"status**:"*stopped*) outcome=stopped ;;
  *"статус:"*готово*|*"статус**:"*готово*|*"status:"*done*|*"status**:"*done*) outcome=done ;;
esac

tools=0; advisor=0; out_tok=0; secs=0
if [ -f "$tr" ]; then
  read -r tools advisor out_tok secs < <(jq -rs '
    [ .[] | select(.type=="assistant") ] as $a
    | ([ $a[].message.content[]? | select(.type=="tool_use") ] | length) as $t
    | ([ $a[].message.content[]? | select((.type=="server_tool_use") and (.name|test("advisor"))) ] | length) as $adv
    | ([ $a[].message.usage.output_tokens? // 0 ] | add // 0) as $o
    | ([ .[] | .timestamp? // empty | sub("\\.[0-9]+Z$";"Z") | fromdateiso8601 ]) as $ts
    | "\($t) \($adv) \($o) \(if ($ts|length)>1 then ($ts|max)-($ts|min) else 0 end)"
  ' "$tr" 2>/dev/null || echo "0 0 0 0")
fi

jq -nc --arg ts "$(date -u +%FT%TZ)" --arg type "$type" \
  --arg aid "$(jq -r '.agent_id // ""' <<<"$input")" \
  --arg sid "$(jq -r '.session_id // ""' <<<"$input")" \
  --arg cwd "$(jq -r '.cwd // ""' <<<"$input")" \
  --arg outcome "$outcome" --argjson retry "$(jq '.stop_hook_active // false' <<<"$input")" \
  --argjson tools "${tools:-0}" --argjson advisor "${advisor:-0}" \
  --argjson out_tok "${out_tok:-0}" --argjson secs "${secs:-0}" \
  '{ts:$ts,type:$type,agent_id:$aid,session:$sid,cwd:$cwd,outcome:$outcome,retry:$retry,tools:$tools,advisor:$advisor,out_tok:$out_tok,secs:$secs}' \
  >>"$HOME/.claude/worker-runs.jsonl"
exit 0
