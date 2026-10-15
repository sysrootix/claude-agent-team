# Install: Opus orchestrates, Haiku executes

```bash
git clone https://github.com/sysrootix/claude-agent-team ~/claude-agent-team
```

Then paste the prompt below into Claude Code (replace the path placeholder if you cloned somewhere else). Claude will then install the scheme into your `~/.claude/` and check it.

---

Install the "Opus orchestrates, Haiku executes" scheme from this folder into my Claude Code. Reply in the user's language.

Repo folder: ~/claude-agent-team

Steps:

1. **Read all files of the folder** (README.md, CLAUDE-orchestration.md, settings-snippet.json, agents/, hooks/, bin/, skills/, verify-templates/, stack-skill-TEMPLATE.md, worker-journal.md) — understand what you are installing.

2. **Check dependencies:** `jq`, `python3`, `perl`, `git` must be in PATH. If something is missing, tell me how to install it (on macOS: `brew install jq`) and wait for me.

3. **Backup:** copy `~/.claude/settings.json` and `~/.claude/CLAUDE.md` (if they exist) into `~/.claude/backup-opus-haiku-<date>/`.

4. **Files** (create folders if they do not exist):
   - `agents/*.md` → `~/.claude/agents/`
   - `hooks/*.sh` → `~/.claude/hooks/` + `chmod +x`; create `~/.claude/hooks/state/`
   - `bin/worker-stats` → `~/.claude/bin/` + `chmod +x`
   - `skills/worker-brief`, `skills/worker-review` → `~/.claude/skills/`
   - `worker-journal.md` → `~/.claude/worker-journal.md` (only if it does not exist yet)

   If a file with the same name already exists and differs — show me the diff and ask; do not overwrite silently.
   If I already have other worker agents (for example on Sonnet or Opus) — list them and ask whether to disable them (move them to `~/.claude/agents-disabled/`, do not delete them).

5. **settings.json — merge, do not replace** (via python3 or jq):
   - `model` → `claude-opus-5-5`; `modelSettings.claude-opus-5-5.effortLevel` → `high`; `advisorModel` → `opus`; `env.CLAUDE_CODE_SUBAGENT_MODEL` → `claude-haiku-5-5`. Leave my other keys and env variables untouched.
   - Add the hooks from `settings-snippet.json` to the end of the arrays `PreToolUse`, `PostToolUse`, `Stop` and `SubagentStop`. Keep my existing hooks. Do not duplicate entries that are already there.
   - After writing, check that the JSON is valid and show me the resulting changes.

6. **CLAUDE.md:** append the content of `CLAUDE-orchestration.md` to the end of `~/.claude/CLAUDE.md` (create the file if it does not exist). If an "# Orchestration" section already exists — replace it, do not duplicate it. If my CLAUDE.md has rules that contradict the new section (other workers, another orchestrator model) — show them to me and ask what to keep.

7. **Hook check (mandatory; do not say "done" without it):**
   - In a temporary folder: `git init`, a file `a.json` containing `{bad`, and `.claude/verify.sh` that prints `fail` and exits with 1.
   - `echo '{"session_id":"t","tool_input":{"file_path":"<folder>/a.json"}}' | ~/.claude/hooks/quick-check.sh` → exit code 2 and a syntax error message.
   - `echo '{"session_id":"t"}' | ~/.claude/hooks/verify-on-stop.sh` → exit code 2 and the text `fail`.
   - The same with `"stop_hook_active":true` → exit code 0 (loop protection).
   - Guard hook: `echo '{"agent_id":"a","tool_input":{"command":"xcrun simctl shutdown all"}}' | ~/.claude/hooks/guard-subagent.sh` → JSON with `"permissionDecision": "deny"`.
   - Delete the temporary folder and `~/.claude/hooks/state/t_*`.

8. **My projects:** ask me which repositories I work in most. For each one (with my "yes"):
   - create `.claude/verify.sh` from a suitable template in `verify-templates/` — fast checks only (≤2 min), no build, no deploy, no network calls; run it. If it is red on the current code — do not fix the code; show me the errors and propose how to exclude the noise (for example, a separate tsconfig for checks), so that it is green on clean code;
   - if the repo has no CLAUDE.md — propose a short one (40–80 lines): what the project is, its structure, check/run commands, patterns with example paths, prohibitions.

   For stacks with their own pitfalls, propose a stack skill based on `stack-skill-TEMPLATE.md` (`~/.claude/skills/stack-<name>/SKILL.md`).

9. **Optional:** suggest LSP plugins for my languages (for example `claude plugin install typescript-lsp@claude-plugins-official`, plus the matching language server).

10. **Summary:** what is installed, what changed in settings.json and CLAUDE.md, where the backup is, and the hook check results. Remind me that the changes take effect in a new session.

---

## Notes

- The agent files do not set `permissionMode`. Workers and reviewers run under the normal permission rules of your session. Adding `permissionMode: bypassPermissions` to the frontmatter of the agents is an option only for those who knowingly work in bypass-permissions mode and understand what it means.
- `hooks/guard-subagent.sh` is a deterministic deny for subagents; it does not replace the brief rules. It only blocks the commands listed in it.
