<p align="center">
  <img src="docs/logo.svg" alt="Claude Code Mastery" width="400">
</p>

<p align="center">
  <strong>Persistent memory, smart hooks, and curated skills for Claude Code CLI.</strong><br>
  Never lose context again.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/alissonlinneker/claude-code-mastery/releases"><img src="https://img.shields.io/badge/version-1.2.2-green.svg" alt="Version 1.2.0"></a>
  <a href="reports/security-2026-03-14.md"><img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Falissonlinneker%2Fclaude-code-mastery%2Fmain%2Fshield-badge.json&query=%24.message&label=Shield%20Score&color=brightgreen" alt="Shield Score"></a>
  <a href="https://github.com/alissonlinneker/claude-code-mastery/actions"><img src="https://github.com/alissonlinneker/claude-code-mastery/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/alissonlinneker/claude-code-mastery/stargazers"><img src="https://img.shields.io/github/stars/alissonlinneker/claude-code-mastery?style=social" alt="GitHub Stars"></a>
</p>

<p align="center"><em>A production-ready configuration system for <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code CLI</a> that transforms it from a stateless assistant into a persistent, context-aware development partner.</em></p>

---

## The Problem

Out of the box, Claude Code CLI:

- **Forgets everything** between sessions — no memory of previous conversations
- **Loses context on compact** — auto-compact summarizes and destroys critical details
- **Doesn't enforce workflows** — skills and best practices are optional and easy to skip
- **Requires manual setup** per project — MCP servers, .gitignore, memory files
- **No diagnostics** — you can't see what's configured at a glance

## The Solution

Claude Code Mastery gives you:

| Feature | What It Does |
|---------|-------------|
| **Perpetual Memory** | 6-file Memory Bank per project, auto-configured via MCP |
| **Smart Hooks** | 6 lifecycle events that preserve context and enforce workflows |
| **26+ Curated Skills** | From 5 marketplaces: Superpowers, Trail of Bits, CEK, Shield, and custom |
| **Zero-Config Launcher** | One command (`claude`) sets up everything automatically |
| **Context7 Integration** | Auto-lookup of up-to-date library documentation |
| **Task Management** | Built-in task tracking as a second persistence layer |

---

## Quick Start

### One-Line Install (macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/alissonlinneker/claude-code-mastery/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/alissonlinneker/claude-code-mastery.git
cd claude-code-mastery
./install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/alissonlinneker/claude-code-mastery/main/install.ps1 | iex
```

Or manually:

```powershell
git clone https://github.com/alissonlinneker/claude-code-mastery.git
cd claude-code-mastery
.\install.ps1
```

> **WSL users:** The bash installer (`install.sh`) auto-detects WSL and is recommended. Use `install.ps1` only for native Windows/PowerShell.

### After Installation

```bash
# macOS/Linux: reload your shell
source ~/.zshrc   # or source ~/.bashrc

# Windows: reload your PowerShell profile
. $PROFILE
```

```bash
# Navigate to any project
cd your-project

# Just run claude — everything is auto-configured
claude
```

On first run in a project, the launcher automatically:
- Creates `.mcp.json` with Memory Bank MCP configuration
- Creates `.memory-bank/` directory for persistent memory
- Adds `.memory-bank/`, `.mcp.json`, `.claude-logs/` to `.gitignore`
- Displays project diagnostics

---

## What You Get

### Session Diagnostics on Every Launch

```
┌──────────────────────────────────────────────┐
│  Claude Code — my-project                    │
└──────────────────────────────────────────────┘

  --- Project Diagnostics ---
  CLAUDE.md       [OK] 7967 bytes
  Memory Bank     [OK] 6 files
    - activeContext.md (1229B)
    - productContext.md (1467B)
    - progress.md (1788B)
    - projectbrief.md (1045B)
    - systemPatterns.md (1621B)
    - techContext.md (2564B)
  MCP             [OK] configured
  Branch          main
  Modified        3 files
  Last commit     f3f5589 fix: improve auth flow

  Log: .claude-logs/session_20260314_143022.log
```

### Perpetual Memory (Memory Bank)

Every project gets 6 persistent memory files that survive across sessions and compactions:

| File | Purpose |
|------|---------|
| `projectbrief.md` | Project overview, goals, scope |
| `productContext.md` | Business rules, features, user flows |
| `techContext.md` | Tech stack, dependencies, configurations |
| `systemPatterns.md` | Architecture decisions, code conventions |
| `activeContext.md` | Current tasks, recent decisions, next steps |
| `progress.md` | What was done, what remains |

Claude is instructed to **read all files at session start** and **write updates after every task** — ensuring context is never lost. See the [Memory Bank Guide](docs/memory-bank.md) for details.

### Smart Hooks (6 Lifecycle Events)

| Hook | When | What It Does |
|------|------|-------------|
| `SessionStart` (startup) | New session | Auto-updates plugin marketplaces |
| `SessionStart` (default) | Every session | Shows diagnostics, instructs Memory Bank read |
| `SessionStart` (compact) | After compaction | Full context restoration from Memory Bank |
| `UserPromptSubmit` | Every user message | Reminds: Memory Bank, Skills, Context7 |
| `PreCompact` | Before compaction | Auto-saves git state snapshot + instructs full context save |
| `Stop` | After each response | Reminds to update Memory Bank on task completion |
| `TaskCompleted` | Task done | Updates Memory Bank and task tracker |
| `PreToolUse` (Bash) | Before bash commands | Blocks dangerous commands (rm -rf, force push, etc.) |

### Curated Skills (26+ from 5 Sources)

**[Superpowers](https://github.com/obra/superpowers) (14 skills)**
Workflow automation: brainstorming, systematic-debugging, test-driven-development, writing-plans, executing-plans, dispatching-parallel-agents, subagent-driven-development, using-git-worktrees, receiving-code-review, requesting-code-review, verification-before-completion, finishing-a-development-branch, writing-skills, using-superpowers

**[Trail of Bits](https://github.com/trailofbits/skills) (5 skills)**
Professional security: differential-review, static-analysis, audit-context-building, supply-chain-risk-auditor, agentic-actions-auditor

**[Context Engineering Kit](https://github.com/NeoLabHQ/context-engineering-kit) (4 skills)**
Quality engineering: sdd (spec-driven development), reflexion, code-review, kaizen

**[Shield](https://github.com/alissonlinneker/shield-claude-skill) (Security orchestrator)**
Automated security scanning: SAST, SCA, secrets detection, compliance mapping, penetration testing

**Custom Skills (3)**
Bundled with this project: architect-review, context-guardian, production-audit

---

## Comparison

| Feature | Vanilla Claude Code | Claude Code Mastery |
|---------|--------------------|--------------------|
| Memory between sessions | None | 6-file Memory Bank per project |
| Context after compact | Lost | Restored from Memory Bank + hooks |
| Project setup | Manual | Auto-configured on `claude` |
| Skills enforcement | Optional | Mandatory with 26+ skills mapped |
| Security analysis | None | Trail of Bits + Shield integration |
| Code quality | Manual | Superpowers + CEK skills |
| Task tracking | None | Built-in task management |
| Library docs | Guessing | Context7 auto-lookup |
| Dangerous commands | Allowed | Blocked by PreToolUse hook |
| Session diagnostics | None | Full project status on launch |
| Cross-platform | CLI only | macOS + Linux + Windows installer |

---

## What Gets Installed

```
~/.claude/
├── CLAUDE.md                 # Global rules (loaded in every session)
├── settings.json             # Hooks + permissions + plugins
├── settings.local.json       # MCP auto-enable
├── skills/
│   ├── architect-review.md   # Architecture evaluation
│   ├── context-guardian.md   # Context preservation
│   └── production-audit.md   # Production readiness audit
├── hooks/
│   └── auto-update-plugins.sh  # Marketplace auto-updater
└── projects/
    └── -default/memory/
        └── MEMORY.md         # Auto-memory index template
```

The installer also appends a `claude_code()` function to your `~/.zshrc` (macOS), `~/.bashrc` (Linux), or PowerShell `$PROFILE` (Windows) that wraps the `claude` CLI with zero-config project setup.

---

## Configuration

See the [Configuration Reference](docs/configuration.md) for detailed documentation of all settings.

### Key Configuration Files

| File | Purpose | Docs |
|------|---------|------|
| `~/.claude/CLAUDE.md` | Global rules for every session | [Configuration](docs/configuration.md) |
| `~/.claude/settings.json` | Hooks, permissions, plugins | [Hooks](docs/hooks.md) |
| `~/.claude/skills/*.md` | Custom skill definitions | [Skills](docs/skills.md) |

### Customization

Claude Code Mastery is designed to be customized. See the [Customization Guide](docs/customization.md) for details.

**Installer flags:**

```bash
./install.sh --interactive          # Guided setup with prompts
./install.sh --lang=pt-BR           # Hook messages in Portuguese
./install.sh --preset=node          # Extra permissions for Node.js
./install.sh --skip-plugins         # Skip marketplace installation
./install.sh --plugins=superpowers  # Install only selected marketplaces
```

**Post-install customization:**

- `scripts/apply-language.sh pt-BR` — Change hook language
- `scripts/apply-preset.sh python` — Apply project preset
- Add your own skills to `~/.claude/skills/`
- Modify hooks in `~/.claude/settings.json`

---

## Uninstalling

```bash
# macOS/Linux
./uninstall.sh

# Windows (PowerShell)
.\uninstall.ps1
```

The uninstaller:
- Restores original configs from `.bak` backups
- Removes custom skills and hooks
- Removes the shell launcher function
- Does **not** remove plugin marketplaces or per-project Memory Bank data

---

## Troubleshooting

See the [Troubleshooting Guide](docs/troubleshooting.md) for common issues.

**Quick fixes:**

| Issue | Solution |
|-------|----------|
| `claude: command not found` | Run `source ~/.zshrc` (or `~/.bashrc`) |
| Memory Bank not reading | Check `.mcp.json` exists in project root |
| Hooks not firing | Verify `~/.claude/settings.json` is valid JSON |
| Plugins not found | Run `claude plugin marketplace add <repo>` manually |
| Permission denied on hook | Run `chmod +x ~/.claude/hooks/auto-update-plugins.sh` |

---

## Roadmap

### v1.0.0 — Initial Release
- [x] Installer for macOS (zsh)
- [x] Installer for Linux (bash)
- [x] All config files as templates
- [x] 3 custom skills
- [x] Auto plugin marketplace setup
- [x] Full documentation
- [x] Uninstaller with backup restore

### v1.1.0 — Windows Support
- [x] PowerShell installer (`install.ps1` / `uninstall.ps1`)
- [x] Windows-compatible hooks (pure PowerShell, no bash dependency)
- [x] WSL detection and setup
- [x] PowerShell launcher function

### v1.2.0 — Customization (Current)
- [x] Interactive installer (`--interactive` flag)
- [x] Selective plugin installation (`--skip-plugins`, `--plugins=LIST`)
- [x] Language template system (`--lang=CODE`: en, pt-BR, es)
- [x] Project-type presets (`--preset=NAME`: general, node, python, php, monorepo)

### v2.0.0 — Advanced
- [ ] Web dashboard for memory visualization
- [ ] Memory Bank analytics
- [ ] Plugin recommendation engine
- [ ] CI/CD integration

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes (all content in English)
4. Run tests: `bash tests/test-install.sh && bash tests/test-hooks.sh`
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, etc.
6. Open a Pull Request

---

## References

| Resource | Link |
|----------|------|
| Claude Code CLI | [docs.anthropic.com/en/docs/claude-code](https://docs.anthropic.com/en/docs/claude-code) |
| Memory Bank MCP | [npmjs.com/package/@allpepper/memory-bank-mcp](https://www.npmjs.com/package/@allpepper/memory-bank-mcp) |
| Superpowers | [github.com/obra/superpowers](https://github.com/obra/superpowers) |
| Trail of Bits Skills | [github.com/trailofbits/skills](https://github.com/trailofbits/skills) |
| Context Engineering Kit | [github.com/NeoLabHQ/context-engineering-kit](https://github.com/NeoLabHQ/context-engineering-kit) |
| Shield | [github.com/alissonlinneker/shield-claude-skill](https://github.com/alissonlinneker/shield-claude-skill) |
| Context7 | [github.com/upstash/context7](https://github.com/upstash/context7) |
| Claude Code Hooks | [docs.anthropic.com/en/docs/claude-code/hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) |
| Claude Code Skills | [docs.anthropic.com/en/docs/claude-code/skills](https://docs.anthropic.com/en/docs/claude-code/skills) |

---

## License

[MIT](LICENSE)
