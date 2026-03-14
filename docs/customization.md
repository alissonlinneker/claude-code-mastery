# Customization Guide

How to tailor Claude Code Mastery to your workflow, preferences, and team conventions.

---

## Language Configuration

Claude Code uses the `language` setting in `~/.claude/settings.json` to determine the response language.

The CLAUDE.md template shipped with Claude Code Mastery is written in English, but Claude adapts its responses to the configured language automatically.

**To set a language preference:**

Add or update the `language` field in `~/.claude/settings.json`:

```json
{
  "language": "pt-BR"
}
```

Common locale values:
- `en` — English
- `pt-BR` — Brazilian Portuguese
- `es` — Spanish
- `fr` — French
- `de` — German
- `ja` — Japanese
- `zh-CN` — Simplified Chinese

This affects Claude's responses but does not change the language of hook scripts, skill files, or configuration templates.

---

## Adding Custom Skills

Skills are Markdown files that define specialized behaviors for Claude. They live in `~/.claude/skills/` and are available in every session.

### Creating a skill

1. Create a `.md` file in `~/.claude/skills/`:

```bash
touch ~/.claude/skills/my-custom-skill.md
```

2. Add the required YAML frontmatter and skill body:

```markdown
---
name: my-custom-skill
description: A short description of what this skill does
---

# My Custom Skill

## When to use
Describe the trigger conditions — when should Claude invoke this skill.

## Steps
1. First step
2. Second step
3. Third step

## Output format
Describe the expected output or deliverable.
```

### Frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier for the skill (kebab-case recommended) |
| `description` | Yes | One-line summary shown when listing available skills |

### Tips

- Keep skills focused on a single task or workflow.
- Use clear trigger conditions so Claude knows when to invoke the skill.
- Skills are loaded at session start — changes take effect in the next session.
- Claude Code Mastery ships with 3 custom skills (`architect-review`, `context-guardian`, `production-audit`) that you can use as reference.

---

## Modifying Hooks

Hooks are defined in `~/.claude/settings.json` under the `hooks` key. Each hook event contains an array of hook entries, so you can add new hooks alongside existing ones without removing defaults.

### Hook events

| Event | Fires when |
|-------|-----------|
| `SessionStart` | A new Claude session begins |
| `UserPromptSubmit` | The user submits a prompt |
| `PreCompact` | Before context compaction |
| `Stop` | After each Claude response |
| `TaskCompleted` | A task is marked complete |
| `PreToolUse` | Before a tool is invoked |

### Adding a custom hook

Edit `~/.claude/settings.json` and add your hook to the appropriate event array:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'User submitted a prompt' >> /tmp/claude-audit.log"
          }
        ]
      }
    ]
  }
}
```

### Matchers

- **Empty string (`""`)** — matches all events of that type.
- **Specific string** — matches only when the event payload contains that string. For `PreToolUse`, the matcher matches against the tool name (e.g., `"Bash"`, `"Write"`, `"Edit"`).

### Example: blocking dangerous commands

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "CMD=$(cat | jq -r '.tool_input.command // empty') && if echo \"$CMD\" | grep -qE 'rm -rf /|:(){ :|:& };:'; then echo '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Dangerous command blocked.\"}}'; fi"
          }
        ]
      }
    ]
  }
}
```

### Tips

- Hook commands receive tool input via stdin (use `cat | jq` to parse).
- For `PreToolUse`, return a JSON deny decision to block the tool call.
- Keep hook commands fast — slow hooks delay every interaction.
- Add a `timeout` field (in seconds) for hooks that may hang.

---

## Adding Plugin Marketplaces

Plugin marketplaces are Git repositories that contain collections of skills and plugins.

### Adding a marketplace

```bash
claude plugin marketplace add owner/repo
```

This clones the marketplace repository and registers it in your settings.

### Manual registration

Add the marketplace to `extraKnownMarketplaces` in `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "your-marketplace-name": {
      "source": { "source": "github", "repo": "your-org/your-marketplace" }
    }
  }
}
```

### Enabling plugins from a marketplace

Add the plugin's full path to `enabledPlugins`:

```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "your-plugin@your-marketplace-name": true
  }
}
```

---

## Customizing Permissions

Permissions control which tools Claude can use automatically (without asking) and which are blocked entirely.

### Auto-approving tools

Add patterns to `permissions.allow` in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git *)",
      "Bash(npm test *)",
      "Bash(npx *)",
      "Write(docs/*)",
      "Edit"
    ]
  }
}
```

### Blocking tools

Add patterns to `permissions.deny`:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(curl * | bash)",
      "Write(.env*)"
    ]
  }
}
```

### Permission format

| Pattern | Matches |
|---------|---------|
| `Read` | All file reads |
| `Write` | All file writes |
| `Edit` | All file edits |
| `Bash(command *)` | Bash commands matching the glob |
| `Write(path/*)` | Writes to files matching the path glob |
| `Bash(git *)` | All git commands |

Deny rules take precedence over allow rules. If a tool call matches both an allow and a deny pattern, it is blocked.

---

## Modifying Memory Bank Triggers

The Memory Bank read/write triggers are defined in the CLAUDE.md template. You can customize when and what gets saved.

### Changing read triggers

Edit the CLAUDE.md template (or your project's CLAUDE.md) to modify the read table:

```markdown
| WHEN | ACTION |
|------|--------|
| Session start | Read ALL .md files in Memory Bank |
| After /compact | Read ALL .md files — restore context |
| Before implementing feature | Read techContext.md and systemPatterns.md |
| Before code review | Read productContext.md |
```

### Changing write triggers

Similarly, update the write table:

```markdown
| WHEN | FILE |
|------|------|
| After completing any task | activeContext.md + progress.md |
| Architectural decision | systemPatterns.md |
| New technical pattern | techContext.md |
| Before compact | activeContext.md (full snapshot) |
```

### Adding custom memory files

The default Memory Bank includes 6 files:

1. `projectbrief.md` — project scope and goals
2. `productContext.md` — business rules and requirements
3. `systemPatterns.md` — architectural decisions
4. `techContext.md` — technical stack and conventions
5. `activeContext.md` — current session state
6. `progress.md` — task tracking

You can add custom files for your project's needs:

```markdown
| WHEN | FILE |
|------|------|
| API endpoint added/changed | apiReference.md |
| Database schema changed | dataModel.md |
| Deployment config changed | infrastructure.md |
```

Add the corresponding read triggers to ensure these files are loaded when relevant.

---

## Creating Project-Specific Rules

Project-level rules are defined in a `CLAUDE.md` file at the project root. These rules override global rules from `~/.claude/CLAUDE.md`.

### Creating a project CLAUDE.md

```bash
touch CLAUDE.md
```

### What to include

```markdown
# Project Rules

## Tech Stack
- Framework: Next.js 14 with App Router
- Language: TypeScript (strict mode)
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest + Playwright

## Conventions
- Use named exports, not default exports
- Components in PascalCase, utilities in camelCase
- All API routes must have input validation with Zod
- Database queries go through the repository pattern

## Team Preferences
- PR descriptions must include a "Test Plan" section
- No abbreviations in variable names
- Maximum file length: 300 lines
- Prefer composition over inheritance
```

### Precedence

1. Project `CLAUDE.md` (highest priority)
2. Global `~/.claude/CLAUDE.md`
3. Claude's default behavior (lowest priority)

Project rules are ideal for encoding team conventions, tech stack specifics, and project-level coding standards that differ from your global preferences.

---

## Changing the Launcher

The shell launcher is a function (`claude_code`) injected into your shell configuration file (`~/.zshrc` or `~/.bashrc`). It is wrapped in guard markers for safe updating.

### Editing the function directly

Look for the section between guard markers in your shell config:

```bash
# >>> claude-code-mastery >>>
claude_code() {
  # ... function body ...
}
# <<< claude-code-mastery <<<
```

You can modify the function body between these markers. Changes take effect after reloading the shell:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### Editing the source templates

For persistent changes that survive re-installation, edit the source files:

- **zsh:** `shell/claude_code.zsh`
- **bash:** `shell/claude_code.bash`

Then re-run the installer to apply:

```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

### Common customizations

**Disable the home directory check:**

Remove or comment out the directory guard in the function body. Note that this is not recommended, as it can lead to Memory Bank files being created in your home directory.

**Add custom pre-launch checks:**

```bash
claude_code() {
  # Custom: check for .env file
  if [ ! -f .env ]; then
    echo "Warning: no .env file found"
  fi

  # ... rest of the function ...
}
```

**Change the log directory:**

Update the log path in the function to write session logs to a different location.

---

## Cross-Reference

- [Configuration](configuration.md) — detailed settings reference
- [Hooks](hooks.md) — hook system deep dive
- [Skills](skills.md) — skill authoring guide
- [Memory Bank](memory-bank.md) — memory architecture details
