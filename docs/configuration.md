# Configuration Reference

Detailed reference for every configuration file installed by Claude Code Mastery, what each field does, and how it all fits together.

---

## Overview — What Gets Installed and Where

The installer places all global configuration under `~/.claude/`:

```
~/.claude/
├── CLAUDE.md                    # Global rules loaded in every Claude Code session
├── settings.json                # Hooks, permissions, plugins, environment
├── settings.local.json          # Local overrides (MCP auto-enable)
├── skills/
│   ├── architect-review.md      # Architecture evaluation skill
│   ├── context-guardian.md      # Context preservation skill
│   └── production-audit.md      # Production readiness audit skill
├── hooks/
│   └── auto-update-plugins.sh   # Marketplace auto-updater script
└── projects/
    └── -default/memory/
        └── MEMORY.md            # Auto-memory index template
```

Additionally, each project gains three local items (created automatically by the shell launcher):

```
your-project/
├── .mcp.json                    # MCP server definitions (Memory Bank)
├── .memory-bank/                # Persistent memory files (6 .md files)
└── .claude-logs/                # Session log files
```

All three are added to `.gitignore` automatically and should never be committed.

---

## CLAUDE.md — Global Rules Template

**Location:** `~/.claude/CLAUDE.md`

This file is loaded by Claude Code at the start of every session, regardless of which project you are in. It defines the behavioral contract that Claude must follow. Below is a section-by-section breakdown.

### Immediate Actions on Session Start

```markdown
1. If `.memory-bank/` exists with files → `memory_bank_read` of EACH `.md` file
2. If a hook indicates "REQUIRED" → follow the instruction BEFORE any response
3. Check which skill applies to the task → invoke via `Skill` tool
```

These three steps run before Claude answers any user message. After `/compact` or `/resume`, the same steps execute again — Claude is instructed to never ask the user what was happening, because the answer is always in the Memory Bank.

### Memory Bank Rules

The Memory Bank section defines when Claude must read from and write to `.memory-bank/` files.

**Mandatory Read triggers:**

| When | Action |
|------|--------|
| Session start | Read ALL `.md` files in `.memory-bank/` |
| After `/compact` | Read ALL `.md` files — restore full context |
| After `/resume` | Read ALL `.md` files — restore full context |
| Before implementing a feature | Read `techContext.md` and `systemPatterns.md` |

**Mandatory Write triggers:**

| When | File |
|------|------|
| After completing any task | `activeContext.md` + `progress.md` |
| Architectural decision made | `systemPatterns.md` |
| Technical pattern discovered | `techContext.md` |
| Before compact | `activeContext.md` (complete snapshot) |
| Project scope defined | `projectbrief.md` |
| Business rules mapped | `productContext.md` |

**Protection rules:**

- Never overwrite without reading first — always use `memory_bank_update` to preserve existing content.
- Never delete memory files, only update them.
- Each project has isolated memory — never cross data between projects.

For full details on Memory Bank architecture, see the [Memory Bank Guide](memory-bank.md).

### Context7 Integration

Context7 provides live documentation lookup for external dependencies. The rules require Claude to use Context7 (via MCP) whenever it works with any external library:

1. `mcp__context7__resolve-library-id` — Find the library's Context7 identifier
2. `mcp__context7__query-docs` — Fetch up-to-date documentation, examples, and API references

**Required triggers:**

- Implementing functionality with an external library or framework
- Questions about a dependency's API
- Updating a dependency version
- Configuring a new tool or plugin
- Debugging errors related to an external library

The key directive: "DO NOT guess APIs. DO NOT use outdated knowledge. ALWAYS consult Context7 first."

### Skills Map

The skills section maps 26+ situations to specific skills that Claude must invoke before taking action. The rule is absolute: if there is even a 1% chance a skill applies, it must be invoked. "It's simple" is treated as a forbidden rationalization.

| Situation | Skill | Source |
|-----------|-------|--------|
| Create feature/component | `brainstorming` | Superpowers |
| Bug/failure/error | `systematic-debugging` | Superpowers |
| Implement feature/bugfix | `test-driven-development` | Superpowers |
| Complex multi-step task | `writing-plans` | Superpowers |
| Execute a plan | `executing-plans` | Superpowers |
| 2+ independent tasks | `dispatching-parallel-agents` | Superpowers |
| Parallel tasks in session | `subagent-driven-development` | Superpowers |
| Git isolation needed | `using-git-worktrees` | Superpowers |
| Code review received | `receiving-code-review` | Superpowers |
| Task/feature complete | `requesting-code-review` | Superpowers |
| Claiming something works | `verification-before-completion` | Superpowers |
| Branch complete | `finishing-a-development-branch` | Superpowers |
| Create/edit skills | `writing-skills` | Superpowers |
| Review architecture | `architect-review` | Custom |
| Large context / pre-compact | `context-guardian` | Custom |
| Audit codebase for production | `production-audit` | Custom |
| Review diff/PR for security | `differential-review` | Trail of Bits |
| Static security analysis | `static-analysis` | Trail of Bits |
| Build audit context | `audit-context-building` | Trail of Bits |
| Supply chain dependency risks | `supply-chain-risk-auditor` | Trail of Bits |
| Security scanning (automated) | `/shield:shield` | Shield |
| Security intelligence (manual) | `/shield:security-auditor` | Shield |
| Spec-driven development | `sdd` | Context Engineering Kit |
| Reflection and refinement | `reflexion` | Context Engineering Kit |
| Continuous improvement | `kaizen` | Context Engineering Kit |
| Code review process | `code-review` | Context Engineering Kit |
| Audit CI/CD for AI agents | `agentic-actions-auditor` | Trail of Bits |

**Auto-compact behavior (80%):** When context reaches 80%, Claude must invoke `context-guardian` to save state, execute `/compact`, re-read Memory Bank, and continue working. It must never refuse to continue by saying "context exhausted."

### Task Management

Task tracking is the second persistence layer alongside Memory Bank:

| When | Action |
|------|--------|
| Session start | List pending tasks |
| User requests something new | Create task with description and priority |
| Start working on task | Update status to `in_progress` |
| Complete task | Update status to `completed` |
| Discover subtask | Create task linked to parent |
| Before compact | List tasks for snapshot in Memory Bank |
| Bug found during work | Create task with `bug` label |

### Git Conventions

- Conventional Commits in English: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- Never push without user confirmation
- Never restore code without authorization

### Security Rules

- Never commit secrets: `.env`, credentials, tokens, API keys
- No AI attribution in commits or public-facing content

### Other Rules

- **Multi-agents:** Independent tasks should be executed in parallel via agents.
- **Quality:** Test everything before finalizing. Check lint/formatting before commit.
- **Planning:** For non-trivial tasks, use plan mode before writing code.
- **Preferences:** Do not over-engineer. Prefer editing existing files over creating new ones. Do not add dependencies without asking.

The template ends with a `<!-- CUSTOMIZE -->` comment where users can add their own project-specific rules.

---

## settings.json — Global Settings

**Location:** `~/.claude/settings.json`

This is Claude Code's global settings file. It controls environment variables, attribution, permissions, hooks, and plugins.

### `env` — Environment Variables

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"
  }
}
```

| Variable | Value | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"` | Enables the experimental Agent Teams feature, allowing Claude to spawn and coordinate multiple sub-agents for parallel task execution. Required for skills like `dispatching-parallel-agents` and `subagent-driven-development`. |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `"80"` | Sets the context window threshold at which auto-compaction triggers. Default is higher; setting to `"80"` gives Claude more room to save context to Memory Bank before compaction occurs. Works in tandem with the `PreCompact` hook and `context-guardian` skill. |

### `attribution` — AI Attribution Control

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

| Field | Value | Purpose |
|-------|-------|---------|
| `commit` | `""` (empty string) | Controls what AI attribution line is added to git commits. An empty string means **no attribution is added** — commits appear as if made by a human developer. |
| `pr` | `""` (empty string) | Controls what AI attribution is added to pull request descriptions. An empty string means **no attribution is added** to PRs. |

Setting these to empty strings removes the default "Co-Authored-By: Claude" trailer from commits and any AI badges from PRs.

### `permissions` — Allow and Deny Lists

```json
{
  "permissions": {
    "allow": [ ... ],
    "deny": [ ... ]
  }
}
```

**Allow list** — Commands that Claude can execute without asking for permission:

| Category | Patterns |
|----------|----------|
| Version control | `Bash(git *)` |
| Package managers | `Bash(npm *)`, `Bash(npx *)`, `Bash(bun *)`, `Bash(pip *)` |
| Runtimes | `Bash(node *)`, `Bash(python3 *)` |
| File inspection | `Bash(cat *)`, `Bash(ls *)`, `Bash(find *)`, `Bash(grep *)`, `Bash(head *)`, `Bash(tail *)`, `Bash(wc *)`, `Bash(stat *)` |
| File manipulation | `Bash(mkdir *)`, `Bash(cp *)`, `Bash(mv *)`, `Bash(touch *)`, `Bash(echo *)` |
| Text processing | `Bash(sort *)`, `Bash(xargs *)`, `Bash(sed *)`, `Bash(awk *)`, `Bash(tee *)` |
| Navigation | `Bash(cd *)`, `Bash(pwd)` |
| Network / APIs | `Bash(curl *)`, `Bash(jq *)`, `Bash(gh *)` |
| Containers | `Bash(docker *)` |
| System | `Bash(which *)`, `Bash(date *)`, `Bash(env *)` |
| File tools | `Read`, `Write`, `Edit`, `MultiEdit` |

**Deny list** — Commands that are always blocked, even if they match an allow pattern:

| Pattern | Why |
|---------|-----|
| `Bash(rm -rf /)` | Prevents recursive deletion of root filesystem |
| `Bash(rm -rf ~)` | Prevents recursive deletion of home directory |
| `Bash(sudo rm *)` | Prevents privileged file deletion |
| `Bash(chmod 777 *)` | Prevents setting world-writable permissions |
| `Bash(git push --force *)` | Prevents force-pushing (which can destroy remote history) |
| `Bash(git push -f *)` | Same as above, short flag form |

The deny list takes precedence over the allow list. The `PreToolUse` hook provides an additional runtime safety layer that intercepts and blocks these patterns before execution.

### `hooks` — Lifecycle Event Hooks

Hooks are commands that execute at specific points in the Claude Code lifecycle. The settings.json defines 6 hook events with 8 total hook entries.

For a comprehensive breakdown of each hook, including the exact commands, matchers, and flow diagrams, see the [Hooks Reference](hooks.md).

**Summary of configured hooks:**

| Event | Matcher | Purpose |
|-------|---------|---------|
| `SessionStart` | `startup` | Runs `auto-update-plugins.sh` to fetch marketplace updates (max once per hour) |
| `SessionStart` | `""` (default) | Displays session diagnostics: CLAUDE.md status, Memory Bank file count, git branch/status. Instructs Claude to read Memory Bank if files exist. |
| `SessionStart` | `compact` | Fires after compaction. Instructs Claude to re-read CLAUDE.md, re-read all Memory Bank files, restore full context, check applicable skills, then continue working. |
| `PreToolUse` | `Bash` | Inspects bash commands via `jq` before execution. Blocks dangerous patterns (`rm -rf /`, `sudo rm`, `chmod 777`, `git push --force`). Returns a deny decision with reason. |
| `PreCompact` | `""` | Fires before compaction. Instructs Claude to save `activeContext.md`, `progress.md`, `techContext.md`, and `systemPatterns.md` to Memory Bank before context is summarized. |
| `UserPromptSubmit` | `""` | Fires on every user message. Outputs a brief reminder: "Memory Bank | Skills | Context7". |
| `Stop` | `""` | Fires after Claude completes a response. Reminds Claude to update Memory Bank and tasks if a task was completed. |
| `TaskCompleted` | `""` | Fires when a task is marked done. Reminds Claude to update `activeContext.md`, `progress.md`, and task tracking. |

Each hook entry has a `timeout` (in seconds) and a `type` (always `"command"` in the default configuration). Hooks that return JSON with `hookSpecificOutput` containing a `permissionDecision` of `"deny"` will block the associated action.

### `enabledPlugins` — Active Plugin Skills

```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "shield@shield-security": true,
    "differential-review@trailofbits": true,
    "static-analysis@trailofbits": true,
    "audit-context-building@trailofbits": true,
    "supply-chain-risk-auditor@trailofbits": true,
    "agentic-actions-auditor@trailofbits": true,
    "sdd@context-engineering-kit": true,
    "reflexion@context-engineering-kit": true,
    "code-review@context-engineering-kit": true,
    "kaizen@context-engineering-kit": true
  }
}
```

Each key follows the format `plugin-name@marketplace-name`. Setting a plugin to `true` enables it globally. The installer activates all 11 plugins by default across 4 marketplaces.

| Marketplace | Plugins | Description |
|-------------|---------|-------------|
| `superpowers-marketplace` | `superpowers` (14 skills) | Workflow automation: brainstorming, TDD, debugging, planning, code review, verification, etc. |
| `shield-security` | `shield` | Automated security orchestration: SAST, SCA, secrets detection, compliance |
| `trailofbits` | 5 plugins | Professional security analysis: differential review, static analysis, audit context, supply chain, agentic actions |
| `context-engineering-kit` | 4 plugins | Quality engineering: spec-driven development, reflexion, code review, kaizen |

### `extraKnownMarketplaces` — Custom Plugin Sources

```json
{
  "extraKnownMarketplaces": {
    "shield-security": {
      "source": { "source": "github", "repo": "alissonlinneker/shield-claude-skill" }
    },
    "trailofbits": {
      "source": { "source": "github", "repo": "trailofbits/skills" }
    },
    "context-engineering-kit": {
      "source": { "source": "github", "repo": "NeoLabHQ/context-engineering-kit" }
    }
  }
}
```

Each entry maps a marketplace name to a GitHub repository. Claude Code clones these repositories locally and uses them as plugin sources. The `superpowers-marketplace` is a built-in known marketplace and does not need to be listed here.

The `auto-update-plugins.sh` hook pulls the latest commits from each marketplace repository at most once per hour on session start.

---

## settings.local.json — Local Settings Override

**Location:** `~/.claude/settings.local.json`

```json
{
  "enableAllProjectMcpServers": true
}
```

| Field | Value | Purpose |
|-------|-------|---------|
| `enableAllProjectMcpServers` | `true` | Automatically enables all MCP servers defined in a project's `.mcp.json` without prompting the user for confirmation. This is essential for the Memory Bank MCP to activate seamlessly when entering any project directory. Without this setting, Claude Code would ask the user to approve each MCP server on every session start. |

This file exists separately from `settings.json` because it contains machine-local preferences that should not be shared across team members or synchronized.

---

## MEMORY.md — Auto-Memory Index Template

**Location:** `~/.claude/projects/-default/memory/MEMORY.md`

This file serves as the auto-memory index that Claude Code uses as a quick-reference cheat sheet at the start of every session. It is installed into the `-default` project memory directory so it applies to all projects that do not have their own override.

The template contains three sections:

### Skills Mapping Table

A lookup table that maps common user requests to the correct skill:

| User Says... | Skill to Invoke |
|--------------|-----------------|
| "create/add/implement X" | `brainstorming` then `writing-plans` then `test-driven-development` |
| "fix/repair X" | `systematic-debugging` |
| "review/audit the code" | `production-audit` or `code-review` |
| "review the architecture" | `architect-review` |
| "check security" | `static-analysis` + `supply-chain-risk-auditor` |
| "review this PR/diff" | `differential-review` |
| "prepare for production" | `production-audit` + `static-analysis` |
| "it's ready/working" | `verification-before-completion` |
| "do X and Y and Z" (multiple) | `dispatching-parallel-agents` |
| "plan how to do X" | `sdd` or `writing-plans` |
| "improve/optimize the project" | `kaizen` + `reflexion` |
| "add dependency X" | `supply-chain-risk-auditor` BEFORE installing |
| "scan for vulnerabilities" | `/shield:shield` or `/shield:security-auditor` |
| Context getting large | `context-guardian` (proactively) |

### Memory Bank Summary

Quick rules for Memory Bank operation:

- **Read:** Session start, after compact, after resume — ALL `.md` files
- **Write:** After tasks, decisions, discoveries, before compact
- **Never overwrite:** Use `memory_bank_update`
- **Context7:** `resolve-library-id` + `query-docs` for library docs. Never guess APIs.

### Installed Plugins Summary

A quick inventory of what is available:

- **Superpowers** — 14 workflow skills
- **Trail of Bits** — 5 security skills
- **Context Engineering Kit** — 4 quality skills
- **Shield** — Security orchestrator
- **Custom skills** — architect-review, context-guardian, production-audit

### Hooks Summary

A one-line reminder of all 6 configured hook events:

```
SessionStart (startup + default + compact) | UserPromptSubmit | PreCompact | Stop | TaskCompleted | PreToolUse (bash safety)
```

---

## Per-Project Files

These files are created automatically by the shell launcher function (`claude_code()`) the first time you run `claude` in a project directory. They should not be committed to version control.

### `.mcp.json` — MCP Server Configuration

**Location:** `<project-root>/.mcp.json`

```json
{
  "mcpServers": {
    "memory-bank": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@allpepper/memory-bank-mcp"],
      "env": {
        "MEMORY_BANK_ROOT": "./.memory-bank"
      }
    }
  }
}
```

| Field | Purpose |
|-------|---------|
| `type` | Communication protocol — `stdio` means the MCP server communicates via stdin/stdout |
| `command` | The command to launch the MCP server — `npx` runs it without global installation |
| `args` | Arguments passed to `npx`: `-y` auto-confirms the install, `@allpepper/memory-bank-mcp` is the package |
| `env.MEMORY_BANK_ROOT` | Directory where Memory Bank files are stored, relative to the project root |

You can add additional MCP servers to this file (e.g., Context7, database connectors, custom tools). Each server is identified by its key name (e.g., `"memory-bank"`).

### `.memory-bank/` — Persistent Memory Directory

**Location:** `<project-root>/.memory-bank/`

Contains up to 6 markdown files that form the project's persistent memory:

| File | Purpose | Written When |
|------|---------|-------------|
| `projectbrief.md` | Project overview, goals, scope | Project scope is defined |
| `productContext.md` | Business rules, features, user flows | Business rules are mapped |
| `techContext.md` | Tech stack, dependencies, configurations | Technical patterns are discovered |
| `systemPatterns.md` | Architecture decisions, code conventions | Architectural decisions are made |
| `activeContext.md` | Current tasks, recent decisions, next steps | After every task, before compact |
| `progress.md` | What was done, what remains | After every task completion |

Files are created on demand — a new project starts with an empty `.memory-bank/` directory and files appear as Claude works on the project.

For a complete guide on Memory Bank architecture, file formats, and best practices, see the [Memory Bank Guide](memory-bank.md).

### `.claude-logs/` — Session Logs

**Location:** `<project-root>/.claude-logs/`

The shell launcher pipes all Claude Code output to timestamped log files:

```
.claude-logs/
├── session_20260314_143022.log
├── session_20260314_161505.log
└── ...
```

Each file is named `session_YYYYMMDD_HHMMSS.log` and contains the complete terminal output of that session. Useful for debugging, auditing, and reviewing what Claude did in previous sessions.

A `.claude-state` file may also exist in this directory, used internally by Claude Code to track session state.

---

## Cross-References

- **[Hooks Reference](hooks.md)** — Detailed breakdown of all 6 hook events, their matchers, commands, and flow diagrams
- **[Skills Reference](skills.md)** — Catalog of all 26+ skills with descriptions, triggers, and usage examples
- **[Memory Bank Guide](memory-bank.md)** — Architecture of the 6-file memory system, file formats, read/write lifecycle
- **[Customization Guide](customization.md)** — How to add your own rules, skills, hooks, permissions, and plugin marketplaces
