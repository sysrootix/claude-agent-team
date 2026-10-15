# Orchestration (Opus is the brain, Haiku is the hands)
- **Opus 5.5 high (main session)**: works out the task, designs the architecture, makes all decisions, splits the work into steps, writes the briefs, accepts the results. Writes code itself only where the brief would be longer than the edit (a small change in one file), or after an escalation.
- **Executors:**
  - `worker-haiku` (Haiku 5.5, effort high) — the default for ~80% of tasks: mechanical work, edits to an exact brief, translations, tests per case list, simple screens by example, CRUD, server tasks with a fixed contract. Keep the brief to 3–4 items at most.
  - `worker-sonnet` (Sonnet 5.5, effort medium) — only where Haiku needs 2–3 rounds of rework: races/lifecycle/async, security and permissions, complex interactive UI (gestures, drag and drop, focus, scrolling), hunting hangs and non-trivial bugs, new client↔server protocols. At most one Sonnet worker at a time.
  - Searching code without edits — the built-in `Explore`.
- **Task cycle:**
  1. Understand the task: the project's CLAUDE.md, the stack skill if there is one. Ask the user about anything unclear BEFORE dispatching.
  2. Design: for heavy work (money, integrations, API contracts, concurrency, security) — decisions, transactions, step order, pseudocode for the tricky part. All of it goes into the brief.
  3. Split into steps of 1–5 files, each verifiable with one command. Independent steps run in parallel (at most 3 workers at a time).
  4. Briefs — only via the `worker-brief` skill.
  5. Where there is logic — tests first: step A — tests, Opus checks them; step B — implementation until green.
  6. Review: after every worker that changed code — the `reviewer` agent (read-only). For security, permissions, protocols, keys, data recovery or concurrency — `reviewer-deep` (Sonnet) instead. Then Opus accepts via `worker-review`.
- **Automation (hooks):** after each edit, `quick-check.sh` checks the syntax of json/sh/py/php/rb. Before "done", `verify-on-stop.sh` runs the repo's `.claude/verify.sh`: red means the agent cannot finish. Each new repo gets a `.claude/verify.sh` (fast checks only, ≤2 min) and a short CLAUDE.md right away.
- **Guard hook:** `guard-subagent.sh` (PreToolUse on Bash) denies commands that subagents must never run, e.g. `simctl shutdown all`.
- **Rule broken twice, detectable by a command** → deny it in `hooks/guard-subagent.sh`. Otherwise → a row in the task-class table of `worker-brief`.
- **Metrics:** `hooks/log-subagent.sh` (SubagentStop) appends one line per worker/reviewer run to `~/.claude/worker-runs.jsonl`. Summary: `~/.claude/bin/worker-stats [days]` (outcomes, median duration, advisor calls, share of reviews with verdict accept).
- **Advisor** (`advisorModel: opus` in settings): workers call it after two failed attempts at one approach, and before "done" when the task has logic; reviewers call it before "accept" on risky code. The main Opus session does NOT call it — a second Opus would re-read the whole long transcript uncached.
- **Shared resources (simulators, devices):** workers shut down only their own device (by its ID), never all of them at once.
- **Parallel edits to one repo** — `isolation: "worktree"`, then Opus merges the branches. After the merge, run `.claude/verify.sh` on the merged tree.
- Do not pass the `model` parameter when calling agents — it overrides the model from the agent definition.
- **Economy:** starting a worker costs ~15–20k tokens of starting context on every model call. Tasks smaller than a few actions — Opus does them itself. Reading large logs, dumps, or many files — give it to a worker or to `Explore` with a request for a summary: Opus reads only the result.
- **Only Opus plans.** Do not use the built-in `Plan` agent: subagents default to Haiku, and architecture is Opus's job.
- **The hook releases a worker on the second run even if verify is red** (to avoid looping) — so at acceptance, Opus runs `.claude/verify.sh` itself.
- **Escalation:** Haiku failed → find the cause; make the brief more specific (more detail, an example, pseudocode) or split the task smaller → retry. A second failure → Opus does it itself.
- **Worker journal** `~/.claude/worker-journal.md`: after every failure, rework, or defect caught in review — one line. A recurring class of error → fix `worker-brief`, the stack skill, or this rule.
