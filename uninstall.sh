#!/usr/bin/env bash
# Claude Code Mastery — Uninstaller
# https://github.com/alissonlinneker/claude-code-mastery
#
# Restores original configs from backups and removes installed files.
# Does NOT remove plugin marketplaces or plugins (you may want to keep them).
#
# Usage:
#   ./uninstall.sh           # Interactive uninstall
#   ./uninstall.sh --force   # Skip confirmations

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────

CLAUDE_DIR="$HOME/.claude"
GUARD_START="# >>> claude-code-mastery >>>"
GUARD_END="# <<< claude-code-mastery <<<"

# ── Colors ─────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Flags ──────────────────────────────────────────────────────────────────────

FORCE=false

# Auto-enable force mode when stdin is not a terminal (e.g., curl | bash)
if [ ! -t 0 ]; then
  FORCE=true
fi

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --help|-h)
      echo "Claude Code Mastery Uninstaller"
      echo ""
      echo "Usage: ./uninstall.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --force   Skip confirmations"
      echo "  --help    Show this help message"
      exit 0
      ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }

restore_backup() {
  local file="$1"
  local backup="${file}.bak"
  local desc="${2:-$(basename "$file")}"

  if [ -f "$backup" ]; then
    cp "$backup" "$file"
    rm "$backup"
    success "Restored $desc from backup"
  elif [ -f "$file" ]; then
    rm "$file"
    success "Removed $desc (no backup to restore)"
  else
    info "$desc not found (already removed)"
  fi
}

# ── Banner ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Claude Code Mastery — Uninstaller               │${NC}"
echo -e "${BOLD}└──────────────────────────────────────────────────┘${NC}"
echo ""

# ── Confirm ────────────────────────────────────────────────────────────────────

if [ "$FORCE" = false ]; then
  echo "  This will:"
  echo "    • Restore original configs from .bak backups"
  echo "    • Remove custom skills (architect-review, context-guardian, production-audit)"
  echo "    • Remove auto-update hook"
  echo "    • Remove shell launcher function"
  echo ""
  echo "  This will NOT:"
  echo "    • Remove plugin marketplaces or installed plugins"
  echo "    • Remove per-project .memory-bank/ or .mcp.json"
  echo "    • Remove session logs (.claude-logs/)"
  echo ""
  read -rp "  Continue? [y/N] " REPLY
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "  Aborted."
    exit 0
  fi
  echo ""
fi

# ── Step 1: Restore config files ──────────────────────────────────────────────

info "Restoring configuration files..."

restore_backup "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
restore_backup "$CLAUDE_DIR/settings.json" "settings.json"
restore_backup "$CLAUDE_DIR/settings.local.json" "settings.local.json"

# ── Step 2: Remove custom skills ──────────────────────────────────────────────

info "Removing custom skills..."

SKILLS=(
  "architect-review.md"
  "context-guardian.md"
  "production-audit.md"
)

for skill in "${SKILLS[@]}"; do
  local_path="$CLAUDE_DIR/skills/$skill"
  if [ -f "$local_path" ]; then
    rm "$local_path"
    success "Removed skill: $skill"
  fi
done

# Remove skills directory if empty
if [ -d "$CLAUDE_DIR/skills" ] && [ -z "$(ls -A "$CLAUDE_DIR/skills" 2>/dev/null)" ]; then
  rmdir "$CLAUDE_DIR/skills"
  info "Removed empty skills/ directory"
fi

# ── Step 3: Remove hook ───────────────────────────────────────────────────────

info "Removing hooks..."

if [ -f "$CLAUDE_DIR/hooks/auto-update-plugins.sh" ]; then
  rm "$CLAUDE_DIR/hooks/auto-update-plugins.sh"
  success "Removed hook: auto-update-plugins.sh"
fi

if [ -f "$CLAUDE_DIR/hooks/pre-compact-save.sh" ]; then
  rm "$CLAUDE_DIR/hooks/pre-compact-save.sh"
  success "Removed hook: pre-compact-save.sh"
fi

# Remove hooks directory if empty
if [ -d "$CLAUDE_DIR/hooks" ] && [ -z "$(ls -A "$CLAUDE_DIR/hooks" 2>/dev/null)" ]; then
  rmdir "$CLAUDE_DIR/hooks"
  info "Removed empty hooks/ directory"
fi

# ── Step 4: Remove MEMORY.md template ─────────────────────────────────────────

info "Removing auto-memory template..."

DEFAULT_MEMORY="$CLAUDE_DIR/projects/-default/memory/MEMORY.md"
if [ -f "$DEFAULT_MEMORY" ]; then
  rm "$DEFAULT_MEMORY"
  success "Removed default MEMORY.md template"
fi

# ── Step 5: Remove shell function ─────────────────────────────────────────────

info "Removing shell launcher function..."

# Find shell config
SHELL_CONFIGS=("$HOME/.zshrc" "$HOME/.bashrc")

for SHELL_CONFIG in "${SHELL_CONFIGS[@]}"; do
  if [ -f "$SHELL_CONFIG" ] && grep -qF "$GUARD_START" "$SHELL_CONFIG" 2>/dev/null; then
    # Remove the block between guard markers (inclusive)
    TEMP_FILE=$(mktemp)
    awk "
      /$GUARD_START/{skip=1; next}
      /$GUARD_END/{skip=0; next}
      !skip{print}
    " "$SHELL_CONFIG" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SHELL_CONFIG"
    success "Removed shell function from $(basename "$SHELL_CONFIG")"
  fi
done

# ── Step 6: Restore global .mcp.json ──────────────────────────────────────────

if [ -f "$HOME/.mcp.json.bak" ]; then
  info "Restoring global ~/.mcp.json from backup..."
  cp "$HOME/.mcp.json.bak" "$HOME/.mcp.json"
  rm "$HOME/.mcp.json.bak"
  success "Restored global ~/.mcp.json"
fi

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Uninstall Complete!                             │${NC}"
echo -e "${BOLD}└──────────────────────────────────────────────────┘${NC}"
echo ""
echo "  Removed:"
echo -e "    ${GREEN}✓${NC} Config files (originals restored from backups)"
echo -e "    ${GREEN}✓${NC} Custom skills (3)"
echo -e "    ${GREEN}✓${NC} Auto-update hook"
echo -e "    ${GREEN}✓${NC} Shell launcher function"
echo ""
echo "  Kept:"
echo "    • Plugin marketplaces and installed plugins"
echo "    • Per-project .memory-bank/ directories"
echo "    • Per-project .mcp.json files"
echo "    • Session logs (.claude-logs/)"
echo ""
echo "  Reload your shell to apply: source ~/.zshrc  (or ~/.bashrc)"
echo ""
