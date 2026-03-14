# Claude Code Mastery — Zero-Config Launcher (bash)
# Source: https://github.com/alissonlinneker/claude-code-mastery
#
# This function wraps the `claude` CLI to auto-configure
# per-project Memory Bank, .gitignore, and session logging.
#
# Usage: claude [args...]

claude_code() {
  local PROJECT_DIR
  PROJECT_DIR="$(pwd)"
  local PROJECT_NAME
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  local LOG_DIR="$PROJECT_DIR/.claude-logs"
  local LOG_FILE="$LOG_DIR/session_$(date +%Y%m%d_%H%M%S).log"

  # ── Guard: prevent setup in home directory ──
  if [ "$PROJECT_DIR" = "$HOME" ]; then
    echo ""
    echo "  ⚠  Cannot run Claude Code Mastery in home directory."
    echo "     Navigate to a project directory first."
    echo ""
    return 1
  fi

  # ── Auto-configure Memory Bank MCP (idempotent) ──
  if [ ! -f "$PROJECT_DIR/.mcp.json" ]; then
    cat > "$PROJECT_DIR/.mcp.json" << 'MCPEOF'
{
  "mcpServers": {
    "memory-bank": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@allpepper/memory-bank-mcp"
      ],
      "env": {
        "MEMORY_BANK_ROOT": "./.memory-bank"
      }
    }
  }
}
MCPEOF
    echo "  [+] Created .mcp.json (Memory Bank MCP)"
  fi

  # ── Create Memory Bank directory ──
  if [ ! -d "$PROJECT_DIR/.memory-bank" ]; then
    mkdir -p "$PROJECT_DIR/.memory-bank"
    echo "  [+] Created .memory-bank/"
  fi

  # ── Update .gitignore (append-only) ──
  local GITIGNORE="$PROJECT_DIR/.gitignore"
  local ENTRIES=(".memory-bank/" ".mcp.json" ".claude-logs/")

  if [ -f "$GITIGNORE" ]; then
    for entry in "${ENTRIES[@]}"; do
      if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
        echo "$entry" >> "$GITIGNORE"
        echo "  [+] Added '$entry' to .gitignore"
      fi
    done
  else
    {
      echo "# Claude Code"
      for entry in "${ENTRIES[@]}"; do
        echo "$entry"
      done
    } > "$GITIGNORE"
    echo "  [+] Created .gitignore"
  fi

  # ── Create log directory ──
  mkdir -p "$LOG_DIR"

  # ── Display diagnostics ──
  echo ""
  echo "┌──────────────────────────────────────────────┐"
  echo "│  Claude Code — $PROJECT_NAME"
  echo "└──────────────────────────────────────────────┘"
  echo ""
  echo "  --- Project Diagnostics ---"

  # CLAUDE.md status
  if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    local CMD_SIZE
    CMD_SIZE=$(stat -f%z "$PROJECT_DIR/CLAUDE.md" 2>/dev/null || stat -c%s "$PROJECT_DIR/CLAUDE.md" 2>/dev/null || echo "?")
    echo "  CLAUDE.md       [OK] ${CMD_SIZE} bytes"
  else
    echo "  CLAUDE.md       [--] not found"
  fi

  # Memory Bank status
  if [ -d "$PROJECT_DIR/.memory-bank" ]; then
    local MB_COUNT
    MB_COUNT=$(find "$PROJECT_DIR/.memory-bank" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MB_COUNT" -gt 0 ]; then
      echo "  Memory Bank     [OK] $MB_COUNT files"
      find "$PROJECT_DIR/.memory-bank" -name '*.md' -type f 2>/dev/null | sort | while read -r f; do
        local FSIZE
        FSIZE=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo "?")
        echo "    - $(basename "$f") (${FSIZE}B)"
      done
    else
      echo "  Memory Bank     [OK] empty (new project)"
    fi
  fi

  # MCP status
  if [ -f "$PROJECT_DIR/.mcp.json" ]; then
    echo "  MCP             [OK] configured"
  fi

  # Git status
  if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    local BRANCH
    BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "detached")
    local MODIFIED
    MODIFIED=$(git -C "$PROJECT_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')
    local LAST_COMMIT
    LAST_COMMIT=$(git -C "$PROJECT_DIR" log --oneline -1 2>/dev/null || echo "no commits")
    echo "  Branch          $BRANCH"
    echo "  Modified        $MODIFIED files"
    echo "  Last commit     $LAST_COMMIT"
  fi

  echo ""
  echo "  Log: $LOG_FILE"
  echo ""

  # ── Launch Claude Code ──
  command claude "$@" 2>&1 | tee -a "$LOG_FILE"
  return "${PIPESTATUS[0]}"
}

# Alias
alias claude='claude_code'
