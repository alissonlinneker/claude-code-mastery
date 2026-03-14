# Hook Reference

Hooks are the backbone of Claude Code Mastery's automation layer. They intercept specific lifecycle events in the Claude Code CLI and run shell commands automatically — injecting context, enforcing rules, blocking dangerous operations, and keeping your Memory Bank in sync.

This document covers every hook handler shipped with Claude Code Mastery, how they work, and how to customize them.

---

## Table of Contents

- [Overview](#overview)
- [Hook Events](#hook-events)
  - [SessionStart (startup)](#sessionstart-startup)
  - [SessionStart (default)](#sessionstart-default)
  - [SessionStart (compact)](#sessionstart-compact)
  - [UserPromptSubmit](#userpromptsubmit)
  - [PreCompact](#precompact)
  - [Stop](#stop)
  - [TaskCompleted](#taskcompleted)
  - [PreToolUse (Bash)](#pretooluse-bash)
- [Hook Execution Order](#hook-execution-order)
- [Custom Hooks](#custom-hooks)
- [Troubleshooting](#troubleshooting)
- [Cross-References](#cross-references)

---

## Overview

Claude Code CLI supports hooks — shell commands that fire automatically at specific lifecycle events. Hooks are defined in `settings.json` under the `"hooks"` key, grouped by event name. Each event can have multiple hook groups, and each group specifies:

| Field | Type | Description |
|-------|------|-------------|
| `matcher` | `string` | Determines which subset of the event triggers this hook. An empty string (`""`) matches every occurrence. |
| `hooks` | `array` | One or more hook definitions to execute when matched. |
| `hooks[].type` | `string` | Always `"command"` for shell hooks. |
| `hooks[].command` | `string` | The shell command or script to run. |
| `hooks[].timeout` | `number` | Maximum seconds to wait before killing the hook. Optional — defaults vary by event. |

Hook commands run in the project's working directory. Their `stdout` output is passed back to Claude as context. For `PreToolUse` hooks, the output can include a JSON decision object to allow or deny tool execution.

**Key principle:** Hooks are non-interactive. They cannot prompt for user input. They must exit cleanly (exit code 0) or the hook is treated as failed.

---

## Hook Events

### SessionStart (startup)

| Property | Value |
|----------|-------|
| **Event** | `SessionStart` |
| **Matcher** | `startup` |
| **Timeout** | 15 seconds |
| **Purpose** | Auto-update plugin marketplaces on fresh session start |

This hook fires once when Claude Code starts a brand-new session (not after compact or resume). It runs the external script `auto-update-plugins.sh` to pull the latest versions of all registered plugin marketplaces.

**What it does:**

The script at `$HOME/.claude/hooks/auto-update-plugins.sh`:

1. Checks a lock file to prevent concurrent executions.
2. Checks a cache file to skip updates if one was done within the last hour (3600 seconds).
3. Iterates over every git-based marketplace directory under `$HOME/.claude/plugins/marketplaces/`.
4. Runs `git fetch` and `git reset --hard` to pull the latest changes from each marketplace's default branch.
5. Reports which marketplaces were updated, if any.
6. Records the check timestamp to avoid redundant network calls.

**Command:**

```json
{
  "type": "command",
  "command": "$HOME/.claude/hooks/auto-update-plugins.sh",
  "timeout": 15
}
```

**Customization:**

- Change the update interval by editing `UPDATE_INTERVAL` in `hooks/auto-update-plugins.sh` (default: `3600` seconds = 1 hour).
- Add new marketplace sources in the `extraKnownMarketplaces` section of `settings.json` — the script discovers them automatically.
- Increase the timeout if your network is slow. 15 seconds handles most cases, but restricted environments may need more.

---

### SessionStart (default)

| Property | Value |
|----------|-------|
| **Event** | `SessionStart` |
| **Matcher** | `""` (empty — matches every session) |
| **Timeout** | 10 seconds |
| **Purpose** | Show project diagnostics and instruct Memory Bank read |

This hook fires on every session start — fresh, compact, or resume. It acts as the "welcome screen" that orients Claude to the current project.

**What it does:**

1. Checks for `CLAUDE.md` and reports its file size.
2. Scans `.memory-bank/` for `.md` files and lists them.
3. If Memory Bank files exist, outputs: `REQUIRED: Read ALL Memory Bank files (memory_bank_read) BEFORE any action.`
4. If Memory Bank is empty, outputs: `Save context using memory_bank_write when tasks are completed.`
5. Reports the project name (from the current directory).
6. If inside a git repository, reports the current branch, number of modified files, and the last commit.

**Command (summarized):**

```bash
echo '--- Session Context ---'
# Report CLAUDE.md size
# Count and list Memory Bank files
# Show project name, git branch, modified files, last commit
echo '---'
```

**Customization:**

- Add additional diagnostic checks (e.g., Node.js version, Docker status) by appending to the command string.
- Remove the git status section if you work with non-git projects.
- Adjust the `head -20` limit if your Memory Bank has more than 20 files.

---

### SessionStart (compact)

| Property | Value |
|----------|-------|
| **Event** | `SessionStart` |
| **Matcher** | `compact` |
| **Timeout** | 10 seconds |
| **Purpose** | Full context restoration after compaction |

This hook fires specifically after a `/compact` operation. Since compaction discards conversational context, this hook injects the recovery instructions that Claude needs to continue seamlessly.

**What it does:**

Outputs a structured checklist of 5 mandatory recovery actions:

1. Read project `CLAUDE.md` to recover mandatory rules and skills.
2. Read ALL `.md` files in `.memory-bank/` using `memory_bank_read`.
3. Restore full context: in-progress tasks, decisions, modified files.
4. Check applicable skills (brainstorming, debugging, TDD, writing-plans, verification).
5. ONLY THEN continue working where you left off.

Additionally:
- Lists all Memory Bank files found in `.memory-bank/`.
- Reports the current git branch, last commit, and modified files.

**Command (summarized):**

```bash
echo '=== COMPACTED CONTEXT ==='
echo 'REQUIRED ACTIONS BEFORE CONTINUING:'
# 5-step recovery checklist
# List Memory Bank files
# Show git status
echo '=== END COMPACTED CONTEXT ==='
```

**Customization:**

- Add task tracker restore instructions (e.g., `TaskList` call) as a 6th step.
- Include project-specific recovery steps for complex multi-service setups.

---

### UserPromptSubmit

| Property | Value |
|----------|-------|
| **Event** | `UserPromptSubmit` |
| **Matcher** | `""` (empty — matches every prompt) |
| **Timeout** | Default (no explicit override) |
| **Purpose** | Per-message rule reminders |

This hook fires every time the user submits a prompt. It injects a brief reminder into the context to keep Claude aligned with the three core systems.

**What it does:**

Outputs a single line:

```
Memory Bank | Skills | Context7
```

This acts as a lightweight nudge — reminding Claude to:

- Check **Memory Bank** for persistent context.
- Apply the appropriate **Skill** workflow before acting.
- Consult **Context7** for external dependency documentation.

**Command:**

```json
{
  "type": "command",
  "command": "echo 'Memory Bank | Skills | Context7'"
}
```

**Customization:**

- Add more reminders (e.g., `| Todoist` for task tracking, `| Tests` for TDD enforcement).
- Make the output conditional — e.g., only remind about Context7 when `package.json` or `requirements.txt` exists.
- Keep it short. This runs on every message, so verbose output creates noise.

---

### PreCompact

| Property | Value |
|----------|-------|
| **Event** | `PreCompact` |
| **Matcher** | `""` (empty — matches all compactions) |
| **Timeout** | 5 seconds |
| **Purpose** | Save context before compaction |

This hook fires right before the context is compacted (either manually via `/compact` or automatically at the 80% threshold). It is the last chance to persist state before conversational memory is wiped.

**What it does:**

Outputs 4 mandatory steps that Claude must complete before allowing compaction:

1. Save `activeContext.md` to Memory Bank with: current task, decisions made, modified files, next steps.
2. Update `progress.md` with what was done in this session.
3. Update `techContext.md` if there were technical discoveries.
4. Update `systemPatterns.md` if there were architectural decisions.

The output explicitly states: `Compaction should ONLY proceed AFTER saving context.`

**Command (summarized):**

```bash
echo '=== PRE-COMPACT: SAVE CONTEXT NOW ==='
echo 'REQUIRED BEFORE COMPACTION:'
# 4 mandatory Memory Bank save steps
echo '=== END PRE-COMPACT ==='
```

**Customization:**

- Add a step to save task tracker state (e.g., `TaskList` snapshot).
- Add project-specific files that should be saved (e.g., test results, environment state).
- Do NOT increase the timeout significantly — the 5-second window is for outputting instructions, not for performing the actual saves. Claude processes the instructions after the hook completes.

---

### Stop

| Property | Value |
|----------|-------|
| **Event** | `Stop` |
| **Matcher** | `""` (empty — matches every stop) |
| **Timeout** | Default (no explicit override) |
| **Purpose** | Remind to update Memory Bank after task completion |

This hook fires when Claude finishes responding (i.e., when the agent "stops" generating). It serves as a post-action reminder.

**What it does:**

Outputs a single conditional reminder:

```
If task completed: update Memory Bank + tasks
```

This nudges Claude to persist state whenever a meaningful unit of work was completed, without being overly prescriptive about what "completed" means.

**Command:**

```json
{
  "type": "command",
  "command": "echo 'If task completed: update Memory Bank + tasks'"
}
```

**Customization:**

- Make the reminder more specific by listing the Memory Bank files to update.
- Add a git status check to remind about uncommitted changes.
- Add conditional logic — e.g., only remind if `.memory-bank/` exists.

---

### TaskCompleted

| Property | Value |
|----------|-------|
| **Event** | `TaskCompleted` |
| **Matcher** | `""` (empty — matches every task completion) |
| **Timeout** | Default (no explicit override) |
| **Purpose** | Update Memory Bank and task tracker |

This hook fires when Claude Code detects that a task has been completed. Unlike `Stop`, which fires on every response, `TaskCompleted` only fires when the CLI determines a logical task boundary was reached.

**What it does:**

Outputs a specific instruction to update three artifacts:

```
Update: activeContext.md + progress.md + tasks
```

This ensures that:

- `activeContext.md` reflects the new state after the completed task.
- `progress.md` records the completed work.
- The task tracker (e.g., Todoist) is updated to mark the task as done.

**Command:**

```json
{
  "type": "command",
  "command": "echo 'Update: activeContext.md + progress.md + tasks'"
}
```

**Customization:**

- Add more Memory Bank files to update (e.g., `techContext.md` for technical tasks).
- Add a git commit reminder for completed features.
- Trigger an automated test run to validate the completed work.

---

### PreToolUse (Bash)

| Property | Value |
|----------|-------|
| **Event** | `PreToolUse` |
| **Matcher** | `Bash` |
| **Timeout** | 5 seconds |
| **Purpose** | Block dangerous shell commands before execution |

This is the only hook that uses structured JSON output to make permission decisions. It intercepts every `Bash` tool invocation and inspects the command before it runs. If a dangerous pattern is detected, it returns a JSON deny decision that prevents execution.

**What it does:**

1. Reads the tool input from `stdin` (Claude Code pipes the tool call as JSON).
2. Uses `jq` to extract the `.tool_input.command` field.
3. Tests the command against a regex of dangerous patterns:
   - `rm -rf /` or `rm -rf ~` (destructive recursive deletion)
   - `sudo rm` (elevated destructive deletion)
   - `chmod 777` (overly permissive file permissions)
   - `git push -f` or `git push --force` (force push)
4. If a match is found, outputs a JSON deny decision.
5. If no match, outputs nothing (implicit allow).

**Command:**

```bash
CMD=$(cat | jq -r '.tool_input.command // empty') && \
if echo "$CMD" | grep -qE '^rm -rf [/~]|sudo rm|chmod 777|git push .* (-f|--force)|git push (-f|--force)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dangerous command blocked. Use safer alternatives."}}'
fi
```

**Deny decision JSON format:**

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Dangerous command blocked. Use safer alternatives."
  }
}
```

**Important:** The deny decision uses a specific JSON structure that Claude Code recognizes. The `permissionDecision` field must be exactly `"deny"` (or `"allow"` to explicitly permit). Any other value, or no output at all, results in the default behavior (allow).

**Customization:**

- Add more patterns to the `grep -qE` regex. For example, to block `DROP TABLE`:
  ```bash
  grep -qE '^rm -rf [/~]|sudo rm|chmod 777|git push .* (-f|--force)|git push (-f|--force)|DROP TABLE'
  ```
- Add project-specific blocks (e.g., prevent running migrations in production).
- Return a custom `permissionDecisionReason` to explain why the command was blocked.
- This hook works alongside the static `deny` list in `permissions.deny` — both layers apply.

---

## Hook Execution Order

When an event fires, Claude Code processes hook groups in the order they appear in the `settings.json` array. Within each event:

1. **Matcher evaluation** — Claude Code checks each hook group's `matcher` against the event context.
   - `"startup"` — matches only fresh session starts.
   - `"compact"` — matches only post-compaction restarts.
   - `""` (empty string) — matches **every** occurrence of the event. This is the catch-all.
2. **All matching groups run** — if multiple groups match the same event, all of them execute in order.
3. **Within a group** — if a group has multiple hooks in its `hooks` array, they run sequentially.
4. **Output concatenation** — all hook outputs are concatenated and injected into Claude's context.

**Example: SessionStart flow**

For a fresh session start, the following hooks match and run in order:

| Order | Matcher | What runs |
|-------|---------|-----------|
| 1 | `startup` | `auto-update-plugins.sh` (plugin updates) |
| 2 | `""` | Session diagnostics (Memory Bank status, git info) |

For a post-compact restart:

| Order | Matcher | What runs |
|-------|---------|-----------|
| 1 | `""` | Session diagnostics |
| 2 | `compact` | Context recovery instructions |

Note that the `startup` matcher does **not** fire on compact — and the `compact` matcher does **not** fire on fresh startup. The empty matcher (`""`) fires on both.

---

## Custom Hooks

To add your own hooks, edit the `hooks` section of your `settings.json`. Follow these guidelines:

### Adding a New Hook to an Existing Event

Append a new hook group to the event's array:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'My custom session info'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Adding a Hook for a New Event

Add a new key to the `hooks` object. The key must be a valid Claude Code event name:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'About to write a file...'"
          }
        ]
      }
    ]
  }
}
```

### Best Practices

1. **Keep hooks fast.** Slow hooks delay Claude's response. Use appropriate timeouts.
2. **Keep output concise.** Hook output consumes context window space. One line is ideal for frequent hooks like `UserPromptSubmit`.
3. **Use external scripts for complex logic.** Inline commands become unreadable quickly. Move logic to `$HOME/.claude/hooks/your-script.sh`.
4. **Make scripts executable.** Run `chmod +x` on any hook script.
5. **Test hooks independently.** Run the command in your terminal first to verify output and exit codes.
6. **Handle errors gracefully.** Use `set -euo pipefail` in scripts. Return exit code 0 even on non-critical failures to avoid blocking Claude.
7. **Never block interactively.** Hooks cannot prompt for input. Avoid `read`, `select`, or any interactive command.

### Supported Events Reference

| Event | When it fires | Matcher examples |
|-------|---------------|------------------|
| `SessionStart` | Session begins | `startup`, `compact`, `""` |
| `UserPromptSubmit` | User sends a message | `""` |
| `PreCompact` | Before context compaction | `""` |
| `Stop` | Claude finishes a response | `""` |
| `TaskCompleted` | A logical task is completed | `""` |
| `PreToolUse` | Before a tool is executed | Tool name (e.g., `Bash`, `Write`, `Read`) |

---

## Troubleshooting

### Hook Not Firing

- **Check the matcher.** A `startup` matcher will not fire after compact. Use `""` for catch-all behavior.
- **Check the event name.** Event names are case-sensitive (`SessionStart`, not `sessionstart`).
- **Check JSON syntax.** A malformed `settings.json` silently disables all hooks. Validate with `jq . ~/.claude/settings.json`.

### Hook Output Not Appearing

- **Check exit code.** Hooks that exit with a non-zero code may have their output suppressed. Add `|| true` at the end of commands that might fail.
- **Check timeout.** If the hook takes longer than its timeout, it is killed and produces no output. Increase the `timeout` value.
- **Check stderr vs stdout.** Only `stdout` is captured. Redirect stderr if needed: `command 2>&1`.

### PreToolUse Deny Not Working

- **Check JSON format.** The deny decision must be valid JSON with the exact field names: `hookSpecificOutput`, `hookEventName`, `permissionDecision`, `permissionDecisionReason`.
- **Check jq is installed.** The Bash guard hook requires `jq`. Run `which jq` to verify.
- **Check stdin piping.** The tool input is piped via `stdin`. Make sure your command reads from `cat` or stdin.
- **Test the regex.** Run the `grep -qE` pattern manually against your test command to verify it matches.

### Plugin Auto-Update Failing

- **Check script permissions.** Run `chmod +x ~/.claude/hooks/auto-update-plugins.sh`.
- **Check lock file.** If a previous run crashed, the lock file at `/tmp/claude-plugin-update.lock` may be stale. Delete it manually.
- **Check network access.** The script runs `git fetch` against remote repositories. Firewalls or VPNs may block this.
- **Check marketplace directory.** The script expects git repos under `$HOME/.claude/plugins/marketplaces/`. Verify this path exists.

### Hook Runs Too Slowly

- **Reduce network calls.** Cache results and use timestamp checks (like the auto-update script does with its 1-hour interval).
- **Move logic to compiled tools.** Replace heavy bash scripts with faster alternatives if needed.
- **Lower timeout values** to fail fast rather than block the session.

---

## Cross-References

- **[Configuration Reference](configuration.md)** — Full `settings.json` schema including permissions, environment variables, and plugins.
- **[Customization](customization.md)** — How to adapt Claude Code Mastery to your workflow, including hook modifications.
