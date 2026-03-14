# Skills Reference

Claude Code Mastery ships with **26+ curated skills** from 5 sources: Superpowers, Trail of Bits, Context Engineering Kit, Shield, and custom skills bundled with this project.

Skills are invoked automatically by Claude based on the task context. The `CLAUDE.md` rules enforce mandatory skill usage before action — "it's simple" is never a valid reason to skip a skill.

---

## Superpowers (14 Skills)

The [Superpowers marketplace](https://github.com/obra/superpowers) provides workflow automation skills for the full development lifecycle.

| Skill | When to Use | Description |
|-------|------------|-------------|
| `brainstorming` | Before any creative work or feature creation | Structured ideation process that explores options, trade-offs, and approaches before committing to an implementation direction. |
| `systematic-debugging` | When encountering bugs, errors, or unexpected behavior | Methodical root-cause analysis workflow: reproduce, hypothesize, test, verify. Prevents fix-by-guessing. |
| `test-driven-development` | Before writing implementation code | Write tests first, then implement. Ensures code is testable by design and meets requirements from the start. |
| `writing-plans` | For complex multi-step tasks that need structure | Creates detailed implementation plans with steps, dependencies, and acceptance criteria before touching code. |
| `executing-plans` | When you have an implementation plan ready to execute | Follows a written plan step-by-step, checking off items and verifying each step before moving on. |
| `dispatching-parallel-agents` | When there are 2+ independent tasks to run simultaneously | Spins up parallel subagents for independent work streams, then merges results. Maximizes throughput. |
| `subagent-driven-development` | For parallel tasks within the current session | Manages concurrent workstreams in the active session without switching branches or worktrees. |
| `using-git-worktrees` | When git isolation is needed for feature work | Uses `git worktree` to work on features in isolated directories without switching branches in the main repo. |
| `receiving-code-review` | When receiving feedback on code from reviewers | Structured process for incorporating review feedback: understand, prioritize, implement changes, verify. |
| `requesting-code-review` | When completing features and requesting review | Prepares code for review: self-review checklist, PR description, summary of changes and testing. |
| `verification-before-completion` | Before claiming any work is done | Runs verification checks (tests pass, lint clean, behavior correct) before marking a task as complete. |
| `finishing-a-development-branch` | When a branch is ready to integrate into main | End-to-end branch completion: squash/rebase, PR creation, CI checks, Memory Bank update. |
| `writing-skills` | When creating or editing skill definitions | Templates and best practices for authoring new `.md` skill files with proper YAML frontmatter. |
| `using-superpowers` | At conversation start to establish skill usage | Bootstraps the skill system at the beginning of a session, ensuring all applicable skills are loaded. |

---

## Trail of Bits (5 Skills)

The [Trail of Bits skills](https://github.com/trailofbits/skills) bring professional-grade security analysis capabilities.

| Skill | When to Use | Description |
|-------|------------|-------------|
| `differential-review` | When reviewing PRs or diffs for security issues | Security-focused code review that analyzes diffs for vulnerabilities, injection points, auth bypasses, and unsafe patterns. |
| `static-analysis` | Before deploy or when scanning for vulnerabilities | Runs Semgrep-based SAST scanning to find security issues, code quality problems, and known vulnerability patterns. |
| `audit-context-building` | At the start of a security audit | Builds deep understanding of the codebase architecture, trust boundaries, data flows, and attack surface before hunting for vulnerabilities. |
| `supply-chain-risk-auditor` | When adding or updating dependencies | Assesses dependency risk: known vulnerabilities, maintainer trust, typosquatting, excessive permissions, and transitive risks. |
| `agentic-actions-auditor` | When reviewing GitHub Actions workflows for AI agent security | Audits CI/CD pipelines for risks specific to AI-driven automation: token exposure, prompt injection in workflows, excessive permissions. |

---

## Context Engineering Kit (4 Skills)

The [Context Engineering Kit](https://github.com/NeoLabHQ/context-engineering-kit) focuses on structured development and continuous improvement.

| Skill | When to Use | Description |
|-------|------------|-------------|
| `sdd` | For structured, spec-driven development tasks | Spec-Driven Development: write a specification first, then implement against it. Ensures requirements are explicit before coding. |
| `reflexion` | After implementation, for self-refinement | Self-evaluation loop: review what was built, identify gaps, and iterate. Catches issues that testing alone misses. |
| `code-review` | For comprehensive code review with specialized focus | Multi-perspective code review using specialized review agents (security, performance, maintainability, correctness). |
| `kaizen` | Periodically, for continuous project improvement | Identifies incremental improvements across the project: code quality, developer experience, documentation, testing, architecture. |

---

## Shield (Security Orchestrator)

[Shield](https://github.com/alissonlinneker/shield-claude-skill) is an automated security scanning orchestrator that coordinates multiple analysis tools.

| Skill | When to Use | Description |
|-------|------------|-------------|
| `/shield:shield` | When you need automated security scanning | Full automated pipeline: SAST (Semgrep/Bandit), SCA (dependency audit), secrets detection, compliance mapping, and penetration testing — all in one command. |
| `/shield:security-auditor` | For intelligence-driven manual security analysis | Human-guided security analysis layer that interprets scan results, prioritizes findings, and provides actionable remediation guidance. |

---

## Custom Skills (3)

Bundled with Claude Code Mastery and installed to `~/.claude/skills/`.

| Skill | When to Use | Description |
|-------|------------|-------------|
| `architect-review` | Before approving or implementing major architectural changes | Architecture evaluation checklist: separation of concerns, dependency direction, API boundaries, scalability, testability. Produces a structured report with findings and recommendations. |
| `context-guardian` | When context is getting large, or before `/compact` | Extracts and classifies all critical context (P0/P1/P2 priority) from the conversation and persists it to Memory Bank before compaction destroys it. Includes integrity verification. |
| `production-audit` | Before deploy, or for production readiness review | Non-security production audit: performance (N+1 queries, caching, memory leaks), architecture (coupling, circular deps), code quality (complexity, duplication), testing coverage. Complements Shield for security. |

---

## Quick Reference Table

Maps common user requests to the correct skill(s) to invoke.

| User Says... | Skill to Invoke |
|--------------|-----------------|
| "create/add/implement X" | `brainstorming` → `writing-plans` → `test-driven-development` |
| "fix/repair X" | `systematic-debugging` |
| "review/audit the code" | `production-audit` or `code-review` (CEK) |
| "review the architecture" | `architect-review` |
| "check security" | `static-analysis` + `supply-chain-risk-auditor` (Trail of Bits) |
| "review this PR/diff" | `differential-review` (Trail of Bits) |
| "prepare for production" | `production-audit` + `static-analysis` |
| "it's ready/working" | `verification-before-completion` |
| "do X and Y and Z" (multiple) | `dispatching-parallel-agents` |
| "plan how to do X" | `sdd` (CEK) or `writing-plans` |
| "improve/optimize the project" | `kaizen` (CEK) + `reflexion` (CEK) |
| "add dependency X" | `supply-chain-risk-auditor` BEFORE installing |
| "scan for vulnerabilities" | `/shield:shield` (automated) or `/shield:security-auditor` (manual) |
| Context getting large | `context-guardian` (proactively) |

**Rule:** Invoke the skill BEFORE acting. "It's simple" is a forbidden rationalization to skip.

---

## Skill Execution Order

When multiple skills apply to a single task, follow this order:

1. **Process skills first** — brainstorming, systematic-debugging, writing-plans
2. **Implementation skills second** — test-driven-development, executing-plans, sdd
3. **Verification skills last** — verification-before-completion, requesting-code-review

Example flow for a new feature:
```
brainstorming → writing-plans → test-driven-development → executing-plans → verification-before-completion → requesting-code-review
```

---

## Plugin Marketplace Configuration

Skills from external marketplaces are configured in `~/.claude/settings.json` under `enabledPlugins` and `extraKnownMarketplaces`. The `auto-update-plugins.sh` hook keeps marketplaces up-to-date on session startup.

| Marketplace | Repository | Skills |
|-------------|-----------|--------|
| Superpowers | `obra/superpowers` | 14 workflow skills |
| Trail of Bits | `trailofbits/skills` | 5 security skills |
| Context Engineering Kit | `NeoLabHQ/context-engineering-kit` | 4 quality skills |
| Shield | `alissonlinneker/shield-claude-skill` | 2 security orchestration skills |

Custom skills do not require marketplace configuration — they are plain `.md` files in `~/.claude/skills/`.

---

## See Also

- [Configuration Reference](configuration.md) — Full settings.json documentation including plugin configuration
- [Customization Guide](customization.md) — How to add your own skills and modify existing ones
