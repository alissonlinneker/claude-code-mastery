# Memory Bank Guide

## Overview

Memory Bank is the persistent memory system that gives Claude Code context that survives across sessions and compactions. Without it, every conversation starts from zero — Claude has no idea what the project is, what was done last session, or what decisions were made.

With Memory Bank configured, Claude:

- **Reads all memory files at session start** to restore full project context
- **Writes updates after every task** so nothing is lost
- **Preserves context before compact** so auto-compaction doesn't destroy critical details
- **Restores context after compact** by re-reading all memory files

The result: Claude behaves like a developer who has been on the project for months, not minutes.

---

## Architecture

Memory Bank uses the [`@allpepper/memory-bank-mcp`](https://www.npmjs.com/package/@allpepper/memory-bank-mcp) MCP (Model Context Protocol) server. This server exposes three tools to Claude:

| Tool | Purpose |
|------|---------|
| `memory_bank_read` | Read a specific memory file for a project |
| `memory_bank_write` | Create a new memory file (first time only) |
| `memory_bank_update` | Update an existing file without overwriting |

Each project gets its own isolated `.memory-bank/` directory in the project root. Memory is never shared between projects.

### How It Connects

The MCP server is configured per-project in `.mcp.json`:

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

The `settings.local.json` file (`~/.claude/settings.local.json`) enables all project MCP servers automatically:

```json
{
  "enableAllProjectMcpServers": true
}
```

The zero-config launcher (`claude_code()` shell function) creates both files automatically when you run `claude` in any project directory.

---

## The 6 Standard Files

Every project's `.memory-bank/` directory contains 6 Markdown files, each with a specific purpose.

### 1. `projectbrief.md`

**Purpose:** Project overview, goals, scope, and constraints.

**Contains:**
- What the project is and why it exists
- High-level goals and success criteria
- Scope boundaries (what's in, what's out)
- Key stakeholders or users
- Timeline and milestones (if applicable)

**When to write:** When the project scope is first defined or significantly changes.

---

### 2. `productContext.md`

**Purpose:** Business rules, features, user flows, and domain knowledge.

**Contains:**
- Business rules and domain logic
- Feature descriptions and user stories
- User flows and interaction patterns
- Terminology and domain glossary
- Non-functional requirements (performance targets, SLAs)

**When to write:** When business rules are mapped or product requirements are clarified.

---

### 3. `techContext.md`

**Purpose:** Technical stack, dependencies, configurations, and conventions.

**Contains:**
- Language, framework, and runtime versions
- Key dependencies and their purposes
- Development environment setup
- Build, test, and deploy commands
- Technical constraints and limitations
- API integrations and external services

**When to write:** When a technical pattern is discovered or the tech stack changes.

---

### 4. `systemPatterns.md`

**Purpose:** Architecture decisions, code conventions, and design patterns.

**Contains:**
- Architecture style (monolith, microservices, serverless, etc.)
- Directory structure and module organization
- Design patterns in use (repository, factory, observer, etc.)
- Naming conventions and coding standards
- ADRs (Architecture Decision Records) — what was decided and why
- Discarded alternatives and the reasoning

**When to write:** When an architectural decision is made.

---

### 5. `activeContext.md`

**Purpose:** Current state — what's being worked on right now.

**Contains:**
- Tasks in progress and their current state
- Recent decisions that affect ongoing work
- Modified files and the nature of changes
- Open questions and blockers
- Alerts (pitfalls, edge cases, things to be careful about)

**When to write:** After completing any task, and always before compact.

This is the most frequently updated file. It serves as the "working memory" snapshot.

---

### 6. `progress.md`

**Purpose:** Historical record — what's been done and what remains.

**Contains:**
- Completed tasks with results
- Tasks in progress
- Pending tasks with priorities
- Bugs found and their resolution status
- Session history (what was accomplished per session)
- GitHub issue references (if applicable)

**When to write:** After completing any task, when bugs are found, when task status changes.

---

## Mandatory Triggers

### When to Read

| Trigger | Action |
|---------|--------|
| Session start | Read ALL 6 `.md` files from Memory Bank |
| After `/compact` | Read ALL 6 `.md` files — restore full context |
| After `/resume` | Read ALL 6 `.md` files — restore full context |
| Before implementing a feature | Read `techContext.md` and `systemPatterns.md` |

The `SessionStart` hooks enforce this by printing `REQUIRED: Read ALL Memory Bank files` in the session output.

### When to Write

| Trigger | File(s) to Update |
|---------|-------------------|
| After completing any task | `activeContext.md` + `progress.md` |
| Architectural decision made | `systemPatterns.md` |
| Technical pattern discovered | `techContext.md` |
| Before compact | `activeContext.md` (complete snapshot) |
| Project scope defined | `projectbrief.md` |
| Business rules mapped | `productContext.md` |

The `PreCompact`, `Stop`, and `TaskCompleted` hooks remind Claude to write updates.

---

## Protection Rules

Three rules prevent memory corruption:

1. **Never overwrite without reading first.** Always use `memory_bank_read` before `memory_bank_update`. Writing blindly can destroy context saved by a previous session.

2. **Never delete memory files.** Only update them. If information becomes stale, update the file to reflect the current state — don't remove the file.

3. **Use `memory_bank_update` for existing files.** The `memory_bank_write` tool creates new files. For files that already exist, always use `memory_bank_update` to append or modify content without wiping what was there before.

---

## Context7 Integration

[Context7](https://github.com/upstash/context7) is a separate MCP server that complements Memory Bank by providing up-to-date documentation for external libraries and frameworks.

| System | What It Stores |
|--------|---------------|
| Memory Bank | Project-specific knowledge (your code, decisions, patterns) |
| Context7 | Library documentation (APIs, examples, configuration options) |

### How They Work Together

- **Memory Bank** records which libraries the project uses and how they're configured (in `techContext.md`)
- **Context7** provides the actual API documentation when Claude needs to write code using those libraries

### Context7 Usage

Two-step process:

1. `mcp__context7__resolve-library-id` — Find the library's Context7 ID
2. `mcp__context7__query-docs` — Fetch documentation, examples, and API references

**When to use Context7:**
- Implementing functionality with an external library
- Unsure about a dependency's API
- Updating a dependency version
- Debugging an error from an external library

The rule is: **never guess APIs, always consult Context7 first.**

---

## How It Survives Compact

Auto-compact triggers at 80% context usage (`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80` in settings.json). When compaction happens, Claude's conversation is summarized and older details are discarded. Memory Bank ensures nothing critical is lost.

### The Compact Lifecycle

```
1. Context reaches 80%
2. PreCompact hook fires
   → Prints: "SAVE CONTEXT NOW"
   → Claude writes activeContext.md, progress.md, techContext.md, systemPatterns.md
3. Compaction occurs
   → Conversation is summarized, detail is lost
4. SessionStart (compact) hook fires
   → Prints: "REQUIRED ACTIONS BEFORE CONTINUING"
   → Lists all Memory Bank files to read
5. Claude reads all Memory Bank files
   → Full context is restored
6. Work continues where it left off
```

### What Each Hook Does

| Hook | Role in Compact Survival |
|------|-------------------------|
| `PreCompact` | Triggers context save to Memory Bank |
| `SessionStart` (compact) | Triggers context restore from Memory Bank |
| `context-guardian` skill | Provides structured P0/P1/P2 extraction when context is large |

The `context-guardian` custom skill adds a layer on top of the hooks. When context is getting large (before the 80% threshold), it proactively extracts and classifies information by priority:

- **P0 (Fatal Loss):** Technical decisions, task state, applied fixes, modified code, errors
- **P1 (Severe Loss):** Discovered patterns, component dependencies, project context
- **P2 (Summary):** History of attempts, progress metrics, discarded options

---

## Best Practices

### What to Store

- Decisions and their reasoning (especially discarded alternatives)
- Current task state and next steps
- Bug fixes with root cause analysis
- File paths that were modified and why
- Architecture patterns and conventions
- Dependencies and their configurations

### What NOT to Store

- Full file contents (Memory Bank files should be concise summaries)
- Temporary debugging output
- Sensitive data (API keys, tokens, passwords)
- Verbose logs or stack traces (store the summary, not the full trace)
- Information that can be derived from the codebase itself

### Writing Effective Memory

- **Be specific:** "Fixed auth bug in `src/auth/login.ts` line 42 — was checking wrong token field" is better than "fixed a bug"
- **Record the why:** "Chose PostgreSQL over MongoDB because we need ACID transactions for payments" is better than "using PostgreSQL"
- **Note what was discarded:** "Considered Redux but chose Zustand for simpler API and smaller bundle" helps prevent revisiting settled decisions
- **Keep it current:** Stale information is worse than no information. Update files when things change.

---

## Troubleshooting

### MCP Server Not Configured

**Symptom:** Claude says "memory_bank_read is not available" or doesn't read memory files.

**Fix:** Ensure `.mcp.json` exists in the project root:
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

Also verify `~/.claude/settings.local.json` contains:
```json
{
  "enableAllProjectMcpServers": true
}
```

### Memory Files Not Being Read at Session Start

**Symptom:** Claude starts fresh without project context despite `.memory-bank/` existing.

**Fix:**
1. Check that the `SessionStart` hook in `~/.claude/settings.json` is printing the "REQUIRED" message
2. Verify `.memory-bank/` contains `.md` files (run `ls .memory-bank/`)
3. Check that `CLAUDE.md` contains the Memory Bank rules
4. Restart Claude Code (`claude` command) — MCP servers initialize on startup

### `memory_bank_update` Fails

**Symptom:** Error when trying to update a memory file.

**Fix:**
- If the file doesn't exist yet, use `memory_bank_write` first to create it
- Ensure the project name matches (the MCP server uses the project directory name)
- Check that Node.js and `npx` are available in your PATH

### Memory Bank Directory Not Created

**Symptom:** No `.memory-bank/` directory in the project root.

**Fix:** The `claude_code()` shell function creates this directory automatically. If you're running `claude` directly (without the shell wrapper), create it manually:
```bash
mkdir -p .memory-bank
```

Then add it to `.gitignore`:
```bash
echo '.memory-bank/' >> .gitignore
```

### Context Lost After Compact

**Symptom:** Claude loses context after auto-compact even though Memory Bank exists.

**Fix:**
1. Verify the `PreCompact` hook exists in `~/.claude/settings.json`
2. Check that the `SessionStart` (compact) hook is configured with the `"matcher": "compact"` variant
3. If using the `context-guardian` skill, invoke it proactively when context is getting large — don't wait for the 80% threshold

### Memory Files Are Empty or Minimal

**Symptom:** Memory Bank files exist but contain very little useful information.

**Fix:** This usually means the `Stop` and `TaskCompleted` hooks aren't prompting Claude effectively. Verify these hooks exist in `settings.json`. You can also explicitly ask Claude to "save context to Memory Bank" after significant work.

---

## See Also

- [Configuration Reference](configuration.md) — Full settings.json documentation including MCP and hook configuration
- [Hooks Reference](hooks.md) — Detailed documentation of all 6 lifecycle hooks
- [Customization Guide](customization.md) — How to modify Memory Bank behavior and add custom memory files
