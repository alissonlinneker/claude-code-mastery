#!/usr/bin/env bash
# Claude Code Mastery — Pre-Compact Auto-Save
# Automatically snapshots session state to Memory Bank before compaction.
# This runs as a hook, independent of Claude's cooperation.
#
# Saves: git status, recent changes, branch, timestamp to activeContext.md

set -euo pipefail

MEMORY_BANK=".memory-bank"
ACTIVE_CONTEXT="$MEMORY_BANK/activeContext.md"

# Only run if Memory Bank exists
if [ ! -d "$MEMORY_BANK" ]; then
  echo "=== PRE-COMPACT: SAVE CONTEXT NOW ==="
  echo "REQUIRED BEFORE COMPACTION:"
  echo "1. Save activeContext.md to Memory Bank with: current task, decisions made, modified files, next steps"
  echo "2. Update progress.md with what was done in this session"
  echo "3. Update techContext.md if there were technical discoveries"
  echo "4. Update systemPatterns.md if there were architectural decisions"
  echo "Use memory_bank_write or memory_bank_update for each file."
  echo "Compaction should ONLY proceed AFTER saving context."
  echo "=== END PRE-COMPACT ==="
  exit 0
fi

# Auto-snapshot: append session state to activeContext.md
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SNAPSHOT=""

SNAPSHOT="
## Auto-Snapshot — $TIMESTAMP (pre-compact)
"

# Git state
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
  MODIFIED_FILES=$(git diff --name-only 2>/dev/null | head -20)
  STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -20)
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -10)

  SNAPSHOT+="
### Git State
- Branch: $BRANCH
- Last commit: $LAST_COMMIT
"

  if [ -n "$MODIFIED_FILES" ]; then
    SNAPSHOT+="
### Modified Files
$(echo "$MODIFIED_FILES" | sed 's/^/- /')
"
  fi

  if [ -n "$STAGED_FILES" ]; then
    SNAPSHOT+="
### Staged Files
$(echo "$STAGED_FILES" | sed 's/^/- /')
"
  fi

  if [ -n "$UNTRACKED" ]; then
    SNAPSHOT+="
### Untracked Files
$(echo "$UNTRACKED" | sed 's/^/- /')
"
  fi
fi

SNAPSHOT+="
### Note
This snapshot was auto-saved by the PreCompact hook. Claude should read this after compact to restore context. For full context, also read progress.md, techContext.md, and systemPatterns.md.
"

# Write snapshot
if [ -f "$ACTIVE_CONTEXT" ]; then
  # Prepend snapshot to existing content (most recent first)
  EXISTING=$(cat "$ACTIVE_CONTEXT")
  echo "$SNAPSHOT" > "$ACTIVE_CONTEXT"
  echo "$EXISTING" >> "$ACTIVE_CONTEXT"
else
  echo "$SNAPSHOT" > "$ACTIVE_CONTEXT"
fi

# Output instructions for Claude (still useful as reminder)
echo "=== PRE-COMPACT: CONTEXT AUTO-SAVED ==="
echo "Auto-snapshot saved to activeContext.md with git state and timestamp."
echo "STILL RECOMMENDED:"
echo "1. Update activeContext.md with current task details and decisions"
echo "2. Update progress.md with what was done in this session"
echo "3. Update techContext.md if there were technical discoveries"
echo "4. Update systemPatterns.md if there were architectural decisions"
echo "=== END PRE-COMPACT ==="
