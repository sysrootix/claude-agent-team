---
name: worker-review
description: >
  Review a coding-agent diff before accepting it. Use after a worker finishes,
  before merge/commit of agent output, or when the user says "check it", "review",
  "see what it did".
---

# Worker review — acceptance

Do not accept work based on a "done" report. Procedure:
1. Run the `reviewer` agent (read-only): give it the brief and the repo. Verify its findings yourself — reproduce them, do not accept blindly.
2. Yourself: `git diff --stat`, then the changed hunks. For heavy tasks — the full diff.
3. Run `.claude/verify.sh` yourself. The hook releases a worker on the second run even if verify is red, to avoid looping.

## Checklist
- Diverges from the brief / unrequested extra work → do not accept.
- Edge cases from the brief are actually handled (not just the ones covered by tests).
- Money: integer arithmetic, transactions, idempotency, no read-then-write.
- Security: secrets in code or logs, permission checks, injection, IDOR.
- Leftovers: TODO / "later", commented-out code, debug output, deleted or disabled tests and checks.
- Changes in the wrong repo / on the wrong host → stop.
- Project patterns (CLAUDE.md, stack skill) followed.

## After merging several branches
Branches being green individually is not acceptance. After merging all branches of a task, run `.claude/verify.sh` and the tests on the MERGED tree (two rules from different branches once conflicted only in combination). A red result after the merge is fixed by Opus or by the worker of the branch that was merged last.

## Verdict
One phrase: accept / return to worker (what to fix — concretely) / finish it yourself. Not "looks fine overall".
A failure, rework, or defect caught in review → a line in `~/.claude/worker-journal.md`.
