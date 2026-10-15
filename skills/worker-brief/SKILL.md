---
name: worker-brief
description: >
  Turn a user request into a worker spec before spawning a worker. Use before every
  Agent(worker-haiku) call, before a long agent prompt, or when splitting a task
  between parallel workers.
---

# Worker brief

Haiku executes precisely and cheaply, but it does not fill in gaps. All decisions are made by Opus in the brief: what, where, and how. Haiku only implements. A vague brief causes rework, and rework eats all the savings. Until you have a goal, a "done" criterion, and the place to edit — do not start the worker; ask the user.

## Slicing
- One task = one cohesive piece, 1–5 files, verifiable with one command. Larger — split into sequential steps, each accepted separately.
- Parallel tasks must not touch the same files. Parallel edits to one repo — `isolation: "worktree"`, then Opus merges.
- A task that takes only a few actions — Opus does it itself: starting a worker costs ~15–20k tokens of starting context on every model call.

## Template (copy and fill in every field)
```
Project: <name>. Report — in the user's language.
Stack skill: load <name>, if one exists, before the first edit.
Goal: <one line>.
Where: <repo/host> → <files and functions, exact>. Example of the same thing already done in the project: <path:line>.
What to do: <steps 1..N; decisions already made: names, signatures, data format, error codes>.
Edge cases: <list: empty, null, 0, duplicate, repeated request, no permission, ...>.
Do not touch: <files/areas>. No deploys, no writes to production, no git commit (unless stated otherwise).
Check: <exact command; expected result>. In a repo with `.claude/verify.sh` the hook runs it automatically.
Done when: <verifiable criterion>.
Known pitfalls: <1–5 items for this area — the worker starts from zero and does not know them>.
```

## Write tests first (anything with logic)
1. Step A — Haiku writes only tests for the cases listed in the brief and shows that they fail. It does not touch the implementation.
2. Opus reads the tests (they are short): the cases are the right ones, the assertions are meaningful, not `expect(true)`. Accepted tests get committed.
3. Step B — Haiku writes the implementation until green. Changing the tests is forbidden; if a test seems wrong — stop and ask.
Where there is no test framework — replace tests with a smoke scenario: exact requests/commands and the expected result written into the brief.

## Money in code
The brief must say explicitly: "count in whole cents/minor units, not float; percentages — integer arithmetic". Put fractional amounts and fractional percentages into the edge cases (example: 516.8 × 62.5% in float = 32299.999… → a lost unit of currency).

## Task classes → mandatory sections of the brief
(Distilled from the worker journal. If a task matches a class, the section is mandatory — otherwise a rework is almost guaranteed.)

| Task class | What must be written in the brief |
|---|---|
| Protocol / CLI adapter, sockets, events | What to do with an unknown message; cancel/interrupt and error handling at EVERY phase (before init, before session, before turn id); process lifecycle (orphans, kill); event size limit |
| Real-time status, offline, cache | Startup states (before connect, disabled, retry); "connection lost mid-process"; which cached fields are volatile and must not be shown from cache |
| External API (APNs, payment providers, ERP, email provider…) | Limits (payload size, rate limit) and error codes, with a reaction to each (retry / disable / show) |
| Client and server edited in parallel | Type and name of EVERY JSON field (seconds or ISO, string or number) — via a contract fixture, see below |
| Button/action that can repeat (create, send) | Repeated click and repeated request: dedupe/lock; reset dependent state when the parent changes |
| One event → N items (album, batch) | List ALL consumers of the event id; key — id + index/source |
| Links, extensions, cold start | "Link before initialization/lock" order; what the person sees for each outcome (drop, error, offline) |
| Anonymization, data trimming | What to KEEP (counters, sound, channel), not only what to remove |
| Changing constants, widths, model fields | "Find and update the tests that check these constants/fields", even if running tests is forbidden |
| Timer and real-time tests | Wait for a condition with a deadline, not a fixed sleep; 2× margin over the threshold |
| UI tests and builds | No visible windows on the host; simulator — a specific UDID, do not touch the others |
| User identity on the server | Name the identity source explicitly (verified token/session); do not write "as in the sample" — the sample may be unsafe |
| Codegen/ORM client in a shared prod node_modules | Regenerate only after the DB migration is applied |

**Contract before parallel workers.** If the client and the server (or two modules) are built by different workers at the same time, Opus first puts a contract fixture into the repo: an example request and response for each method with real types (`fixtures/contract/<method>.json`). Both briefs reference it; the tests on both sides read this fixture. When a field changes, the fixture changes, and both workers re-verify.

## Heavy (money, payments, integrations, API contracts, concurrency, security)
Opus writes the architecture and all decisions into the brief itself: transactions, locks, idempotency, step order, pseudocode for any non-trivial part. Haiku only translates this into code. Acceptance — the reviewer + Opus reads the full diff.
