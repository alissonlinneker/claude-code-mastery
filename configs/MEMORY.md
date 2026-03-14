# Main Memory

## Skills — Mapping Requests to Skills

| USER SAYS... | SKILL TO INVOKE |
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
| context getting large | `context-guardian` (proactively) |

**Rule:** Invoke skill BEFORE acting. "It's simple" = forbidden rationalization.

## Memory Bank MCP — Permanent Memory

- **Read:** Session start, after compact, after resume — ALL `.md` files.
- **Write:** After tasks, decisions, discoveries, before compact.
- **Never overwrite:** Use `memory_bank_update`.
- **Context7:** `resolve-library-id` + `query-docs` for library docs. NEVER guess APIs.

## Installed Plugins

- **superpowers** — 14 workflow skills (brainstorming, TDD, debugging, planning, etc.)
- **Trail of Bits** — 5 security skills (differential-review, static-analysis, audit-context-building, supply-chain-risk-auditor, agentic-actions-auditor)
- **Context Engineering Kit** — 4 quality skills (sdd, reflexion, code-review, kaizen)
- **Shield** — Security orchestrator: automated scanning, SAST, SCA, secrets detection, compliance
- **Custom skills** (~/.claude/skills/): architect-review, context-guardian, production-audit

## Hooks: 6 Events

SessionStart (startup + default + compact) | UserPromptSubmit | PreCompact | Stop | TaskCompleted | PreToolUse (bash safety)
