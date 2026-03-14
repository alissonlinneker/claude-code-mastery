# Immediate Actions on Session Start

**BEFORE responding to any user message, execute these steps:**

1. If `.memory-bank/` exists with files → `memory_bank_read` of EACH `.md` file
2. If a hook indicates "REQUIRED" → follow the instruction BEFORE any response
3. Check which skill applies to the task → invoke via `Skill` tool

**After /compact or /resume:** This CLAUDE.md is reloaded automatically. Execute the 3 steps above IMMEDIATELY. NEVER ask the user what was being done — the answer is in the Memory Bank. Continue where you left off.

---

# Primary Rules

## Memory Bank — Persistent Memory (MCP)

`.memory-bank/` is the project's permanent memory. It persists between sessions. **Without it, every session starts from zero.**

### Mandatory Read

| WHEN | ACTION |
|------|--------|
| Session start | `memory_bank_read` of ALL `.md` files in Memory Bank |
| After `/compact` | `memory_bank_read` of ALL `.md` files — restore context |
| After `/resume` | `memory_bank_read` of ALL `.md` files — restore context |
| Before implementing a feature | `memory_bank_read` of `techContext.md` and `systemPatterns.md` |

### Mandatory Write

| WHEN | FILE |
|------|------|
| After completing any task | `activeContext.md` + `progress.md` |
| Architectural decision | `systemPatterns.md` |
| Technical pattern discovered | `techContext.md` |
| Before compact | `activeContext.md` (complete snapshot) |
| Project scope defined | `projectbrief.md` |
| Business rules mapped | `productContext.md` |

### Protection

- **NEVER overwrite** without reading first. Use `memory_bank_update` to preserve content.
- **NEVER delete** memory files. Only update.
- Each project has isolated memory. NEVER cross between projects.

## Context7 — Dependency Documentation

Use Context7 WHENEVER working with any external dependency (npm, pip, composer, etc.):

1. `mcp__context7__resolve-library-id` → find the library ID
2. `mcp__context7__query-docs` → fetch up-to-date documentation, examples, APIs

**Required triggers for Context7:**
- Implementing functionality with external library/framework
- Questions about a dependency's API
- Updating dependency version
- Configuring new tool/plugin
- Debugging error related to external library

**DO NOT guess APIs. DO NOT use outdated knowledge. ALWAYS consult Context7 first.**

---

## Skills — Required Workflows (NEVER SKIP)

**If there is even a 1% chance a skill applies, it MUST be invoked.** Rationalizing to skip is forbidden.

| SITUATION | SKILL |
|-----------|-------|
| Create feature/component | `brainstorming` → BEFORE code |
| Bug/failure/error | `systematic-debugging` → BEFORE fix |
| Implement feature/bugfix | `test-driven-development` → BEFORE implementation |
| Complex multi-step task | `writing-plans` → BEFORE touching code |
| Execute a plan | `executing-plans` |
| 2+ independent tasks | `dispatching-parallel-agents` |
| Parallel tasks in session | `subagent-driven-development` |
| Git isolation | `using-git-worktrees` |
| Code review received | `receiving-code-review` |
| Complete task/feature | `requesting-code-review` |
| Claim something works | `verification-before-completion` → BEFORE the claim |
| Branch complete | `finishing-a-development-branch` |
| Create/edit skills | `writing-skills` |
| Review architecture | `architect-review` → BEFORE architectural changes |
| Large context / pre-compact | `context-guardian` → when context is getting large |
| Audit codebase for production | `production-audit` → before deploy or review |
| Review diff/PR for security | `differential-review` (Trail of Bits) → on PRs and diffs |
| Static security analysis | `static-analysis` (Trail of Bits) → before deploy |
| Build audit context | `audit-context-building` (Trail of Bits) → start of audit |
| Supply chain risks | `supply-chain-risk-auditor` (Trail of Bits) → when adding deps |
| Security scanning | `/shield:shield` → automated security orchestration |
| Security intelligence | `/shield:security-auditor` → manual security analysis |
| Spec-driven development | `sdd` (Context Engineering Kit) → for structured tasks |
| Reflection and refinement | `reflexion` (CEK) → after implementation to improve |
| Continuous improvement | `kaizen` (CEK) → periodically to optimize |
| Code review process | `code-review` (CEK) → structured multi-agent review |
| Audit CI/CD for AI agents | `agentic-actions-auditor` (Trail of Bits) → on GitHub Actions |

**Auto-compact (80%):** Auto-compact triggers at 80% context. NEVER refuse to continue saying "context exhausted" or "open a new session". Instead:
1. Invoke `context-guardian` to save state to Memory Bank
2. Execute `/compact` if auto-compact hasn't triggered
3. After compact, re-read Memory Bank and continue working
4. Use subagents (Agent tool) for large tasks that consume too much context

**Rules:** Skill BEFORE action. "It's simple" = rationalization. Even after compact. Process skills first (brainstorming, debugging), then implementation skills.

---

## Task Management

**Rule: EVERY task SHOULD be tracked. No exceptions.**

| WHEN | ACTION |
|------|--------|
| Session start | `TaskList` to see pending tasks |
| User requests something new | `TaskCreate` with description and priority |
| Start working on task | `TaskUpdate` → status `in_progress` |
| Complete task | `TaskUpdate` → status `completed` |
| Discover subtask | `TaskCreate` linked to parent task |
| Before compact | `TaskList` for snapshot in Memory Bank |
| Bug found during work | `TaskCreate` with label `bug` |

**Benefit:** After compact/resume, task tracking preserves EVERYTHING that was in progress. It's the second persistence layer alongside Memory Bank.

---

## Multi-Agents

- **Prioritize multi-agents:** Independent tasks → execute in parallel via agents.

## Security

- **Never commit secrets:** `.env`, credentials, tokens, API keys.

## Git

- Conventional Commits in English (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`).
- Never push without confirmation. Never restore code without authorization.

## Quality

- Test everything before finalizing. Check lint/formatting before commit.

## Planning

- For non-trivial tasks, use `EnterPlanMode` before writing code.

## Preferences

- Don't over-engineer. Prefer editing over creating. Don't add dependencies without asking.

<!-- CUSTOMIZE: Add your own rules below this line -->
