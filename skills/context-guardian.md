---
name: context-guardian
description: Use AUTOMATICALLY when context is getting large (60-70% window), before /compact, or when the user mentions preserving context. Extracts, classifies, verifies and persists all critical information to Memory Bank MCP before compaction destroys it.
---

# Context Guardian

Context protection against loss during compaction. Extracts, classifies, verifies, and persists critical data to Memory Bank MCP.

## Automatic Activation (without user request)

- When context is getting large (many tool calls, many edited files)
- When the PreCompact hook fires
- Before long tasks that may push context beyond the limit
- When many technical decisions have accumulated in the session

## Manual Activation

- "save context", "checkpoint", "snapshot", "preserve state"

## Phase 1: Priority Extraction

Scan the entire conversation and extract by priority:

### P0 — Fatal Loss (write to Memory Bank IMMEDIATELY)

| Category | What to Extract | Where to Write |
|----------|----------------|----------------|
| Technical decisions | Choice + reason + discarded alternatives | `systemPatterns.md` |
| Task state | What was done, what remains, dependencies | `activeContext.md` |
| Applied fixes | Bug, root cause, solution, affected files | `progress.md` |
| Modified code | Exact path, lines, nature of change | `activeContext.md` |
| Errors found | Message, stack trace, how it was resolved | `progress.md` |

### P1 — Severe Loss (write to Memory Bank)

| Category | Where to Write |
|----------|----------------|
| Discovered patterns | `techContext.md` |
| Component dependencies | `systemPatterns.md` |
| Project context | `projectbrief.md` |
| Business rules / product context | `productContext.md` |
| Open questions | `activeContext.md` |

### P2 — Compact Summary (write if time permits)

| Category | Where to Write |
|----------|----------------|
| History of attempts | `progress.md` |
| Progress metrics | `progress.md` |
| Brainstorm/discarded options | `systemPatterns.md` |

## Phase 2: Integrity Verification

Before considering the snapshot complete, verify EACH item:

- [ ] Each modified file has: path, nature of change, reason
- [ ] Each fixed bug has: symptom, root cause, solution, file
- [ ] Each decision has: what, why, discarded alternatives
- [ ] Each pending task has: description, priority, dependencies
- [ ] No information contradicts another
- [ ] File paths are complete

If any item fails → return to Phase 1 and re-extract.

## Phase 3: Memory Bank Persistence

Use `memory_bank_update` (NEVER `memory_bank_write` for existing files) to write to each relevant Memory Bank file. Structure:

**`activeContext.md`** — Snapshot of current state:

```
## Current State — [date]

### In Progress
- [task]: [state] — [next step]

### Completed This Session
1. [task] — [result]

### Critical Decisions (do not change without reason)
- [decision]: [reason]

### Applied Fixes (do not revert)
- [file]: [fix] — [reason]

### Next Steps
1. [task] — [priority]

### Alerts
- [pitfalls, edge cases, cautions]
```

## Quick Protocol (when time is short)

If compaction is imminent:
1. **30s** — Write to `activeContext.md`: pending tasks + critical decisions
2. **1min** — Update `progress.md` with what was done
3. **2min** — Update `techContext.md` and `systemPatterns.md` if there were discoveries

Even the quick protocol is better than losing everything.

## Post-Compact

When the session continues after compaction:
1. Read ALL Memory Bank files via `memory_bank_read`
2. Verify if the context is complete
3. If gaps are found → inform the user what may have been lost
4. Continue work exactly where it left off
