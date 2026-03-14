#!/usr/bin/env bash
# Auto-update Claude Code plugin marketplaces
# Runs automatically on SessionStart for each new session
# Checks at most once per hour to avoid unnecessary network calls

set -euo pipefail

MARKETPLACE_BASE="$HOME/.claude/plugins/marketplaces"
LOCK_FILE="/tmp/claude-plugin-update.lock"
CACHE_FILE="/tmp/claude-plugin-last-update"
UPDATE_INTERVAL=3600  # Check at most once per hour (in seconds)

# Avoid concurrent executions
if [ -f "$LOCK_FILE" ]; then
  exit 0
fi

# Check if we already updated recently
if [ -f "$CACHE_FILE" ]; then
  LAST_UPDATE=$(cat "$CACHE_FILE" 2>/dev/null || echo "0")
  NOW=$(date +%s)
  DIFF=$((NOW - LAST_UPDATE))
  if [ "$DIFF" -lt "$UPDATE_INTERVAL" ]; then
    exit 0
  fi
fi

# Create lock file with cleanup trap
trap 'rm -f "$LOCK_FILE"' EXIT
echo $$ > "$LOCK_FILE"

# Track if any marketplace was updated
UPDATES_FOUND=0

# Check if marketplace base directory exists
if [ ! -d "$MARKETPLACE_BASE" ]; then
  date +%s > "$CACHE_FILE"
  exit 0
fi

# Iterate over all marketplace directories
for MARKETPLACE_DIR in "$MARKETPLACE_BASE"/*/; do
  [ -d "$MARKETPLACE_DIR/.git" ] || continue

  MARKETPLACE_NAME=$(basename "$MARKETPLACE_DIR")

  cd "$MARKETPLACE_DIR" || continue
  OLD_SHA=$(git rev-parse HEAD 2>/dev/null || echo "none")
  git fetch --quiet origin 2>/dev/null || { cd /; continue; }

  # Get default branch name
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  git reset --quiet --hard "origin/$DEFAULT_BRANCH" 2>/dev/null || { cd /; continue; }

  NEW_SHA=$(git rev-parse HEAD 2>/dev/null || echo "none")

  if [ "$OLD_SHA" != "$NEW_SHA" ]; then
    echo "Marketplace '$MARKETPLACE_NAME' updated. Run '/plugin update' to apply changes."
    UPDATES_FOUND=$((UPDATES_FOUND + 1))
  fi
done

# Record timestamp of last check
date +%s > "$CACHE_FILE"

if [ "$UPDATES_FOUND" -gt 0 ]; then
  echo "$UPDATES_FOUND marketplace(s) updated. Consider running '/plugin update' to apply."
fi

exit 0
