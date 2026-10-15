# Worker journal (Haiku)

Record here every case where a worker failed, delivered defective work that review or acceptance caught, or where a task had to be redone. Once a week (or when ≥5 entries of one class have accumulated) — review them: update the brief template (`worker-brief`), the stack skill, or the rule in `~/.claude/CLAUDE.md`.

Rule: if the same class of mistake happens twice and a command can detect it → add a hook (`hooks/guard-subagent.sh`). Otherwise → add a row to the task-class table in `worker-brief`.

Line format:
`DD.MM.YYYY | project | task class | what went wrong | cause (brief / stack knowledge / complexity / tool) | what we changed`

## Entries

## Real examples (one week, anonymized)
- money calc: tests green, reviewer caught a lost cent on a fractional percent (float) → brief now says "integer minor units, never float"
- `simctl shutdown all` run 4× in 3 days despite the brief forbidding it (a global rule overrode the brief) → now blocked by `guard-subagent.sh`
- 8-item brief: Haiku did 1 of 8 and stopped with questions → max 3–4 items per Haiku brief
- client and server built in parallel: `expires_at` parsed as ISO, server sent seconds → contract fixture before parallel workers
- shared layout component: tests and build green, broke only in a live UI check → snapshot of every changed screen required
- worker copied an unsafe identity pattern (spoofable cookie) from the sample file it was pointed to → briefs name the identity source explicitly
- ORM client regenerated in a shared prod node_modules before the migration — would have broken every scheduled job on next restart → caught in review
- review loop on a CLI-protocol adapter: unknown messages hung the process, cancel ignored → brief section "unknown messages + cancel at every phase"
