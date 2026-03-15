#!/usr/bin/env bash
# Claude Code Mastery — Installer (macOS/Linux)
# https://github.com/alissonlinneker/claude-code-mastery
#
# Usage:
#   ./install.sh           # Interactive install
#   ./install.sh --force   # Skip confirmations
#   ./install.sh --dry-run # Preview actions without changes
#
# Safety: backup-first, append-only, idempotent

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
GUARD_START="# >>> claude-code-mastery >>>"
GUARD_END="# <<< claude-code-mastery <<<"
VERSION="1.2.2"

# ── Colors ─────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Flags ──────────────────────────────────────────────────────────────────────

FORCE=false
DRY_RUN=false
INTERACTIVE=false
LANG_CODE="en"
PRESET="general"
SKIP_PLUGINS=false
SELECTED_PLUGINS=""

# Auto-enable force mode when stdin is not a terminal (e.g., curl | bash)
if [ ! -t 0 ]; then
  FORCE=true
fi

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    --interactive) INTERACTIVE=true ;;
    --skip-plugins) SKIP_PLUGINS=true ;;
    --lang=*) LANG_CODE="${arg#--lang=}" ;;
    --preset=*) PRESET="${arg#--preset=}" ;;
    --plugins=*) SELECTED_PLUGINS="${arg#--plugins=}" ;;
    --help|-h)
      echo "Claude Code Mastery Installer v$VERSION"
      echo ""
      echo "Usage: ./install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --force          Skip confirmations"
      echo "  --dry-run        Preview actions without making changes"
      echo "  --interactive    Guided setup with prompts"
      echo "  --lang=CODE      Set hook language (en, pt-BR, es). Default: en"
      echo "  --preset=NAME    Apply project preset (general, node, python, php, monorepo)"
      echo "  --skip-plugins   Skip marketplace and plugin installation"
      echo "  --plugins=LIST   Install only listed marketplaces (comma-separated)"
      echo "  --help           Show this help message"
      exit 0
      ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; }

do_or_dry() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY]${NC}  Would: $*"
    return 0
  fi
  return 1
}

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local backup="${file}.bak"
    if do_or_dry "backup $file → $backup"; then return; fi
    cp "$file" "$backup"
    info "Backed up $(basename "$file") → $(basename "$backup")"
  fi
}

install_file() {
  local src="$1"
  local dest="$2"
  local desc="${3:-$(basename "$dest")}"

  if [ ! -f "$src" ]; then
    error "Source file not found: $src"
    return 1
  fi

  backup_file "$dest"

  if do_or_dry "install $desc → $dest"; then return; fi

  local dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  success "Installed $desc"
}

# ── Banner ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Claude Code Mastery — Installer v${VERSION}          │${NC}"
echo -e "${BOLD}└──────────────────────────────────────────────────┘${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  warn "DRY RUN mode — no changes will be made"
  echo ""
fi

# ── Step 1: Detect OS ─────────────────────────────────────────────────────────

info "Detecting operating system..."

OS="unknown"
SHELL_CONFIG=""

case "$(uname -s)" in
  Darwin*)
    OS="macOS"
    SHELL_CONFIG="$HOME/.zshrc"
    ;;
  Linux*)
    OS="Linux"
    # Check if running in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS="Linux (WSL)"
      info "WSL detected — using bash/Linux installer (recommended for WSL)"
      info "For native Windows/PowerShell, use install.ps1 instead"
    fi
    SHELL_CONFIG="$HOME/.bashrc"
    # Use zshrc if zsh is the default shell
    if [ "$(basename "$SHELL")" = "zsh" ]; then
      SHELL_CONFIG="$HOME/.zshrc"
    fi
    ;;
  *)
    error "Unsupported OS: $(uname -s)"
    error "Use install.ps1 for Windows."
    exit 1
    ;;
esac

success "OS: $OS"
success "Shell config: $SHELL_CONFIG"

# ── Step 2: Check Prerequisites ───────────────────────────────────────────────

info "Checking prerequisites..."

MISSING=()

if ! command -v claude &>/dev/null; then
  MISSING+=("claude (Claude Code CLI — https://docs.anthropic.com/en/docs/claude-code)")
fi

if ! command -v node &>/dev/null && ! command -v npx &>/dev/null; then
  MISSING+=("node/npx (Node.js — https://nodejs.org)")
fi

if ! command -v git &>/dev/null; then
  MISSING+=("git (https://git-scm.com)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  error "Missing prerequisites:"
  for m in "${MISSING[@]}"; do
    echo -e "  ${RED}✗${NC} $m"
  done
  exit 1
fi

success "All prerequisites found"

# ── Step 2b: Interactive mode ─────────────────────────────────────────────────

if [ "$INTERACTIVE" = true ] && [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo ""
  info "Interactive setup — press Enter to accept defaults"
  echo ""

  # Language selection
  echo "  Available languages: en (English), pt-BR (Portuguese), es (Spanish)"
  read -rp "  Hook language [$LANG_CODE]: " REPLY
  [ -n "$REPLY" ] && LANG_CODE="$REPLY"

  # Preset selection
  echo ""
  echo "  Available presets: general, node, python, php, monorepo"
  read -rp "  Project preset [$PRESET]: " REPLY
  [ -n "$REPLY" ] && PRESET="$REPLY"

  # Plugin selection
  echo ""
  echo "  Plugin marketplaces:"
  echo "    1. superpowers (workflow skills)"
  echo "    2. trailofbits (security analysis)"
  echo "    3. context-engineering-kit (quality engineering)"
  echo "    4. shield (security orchestrator)"
  echo ""
  read -rp "  Install all plugins? [Y/n]: " REPLY
  REPLY=${REPLY:-Y}
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    read -rp "  Which marketplaces? (comma-separated numbers, e.g., 1,2): " REPLY
    MARKETPLACE_SELECTION="$REPLY"
  fi

  echo ""
  info "Configuration: lang=$LANG_CODE, preset=$PRESET"
fi

# Validate language file exists
if [ ! -f "$REPO_DIR/configs/i18n/${LANG_CODE}.json" ]; then
  warn "Language '$LANG_CODE' not found, falling back to 'en'"
  LANG_CODE="en"
fi

# Validate preset file exists
if [ ! -f "$REPO_DIR/configs/presets/${PRESET}.json" ]; then
  warn "Preset '$PRESET' not found, falling back to 'general'"
  PRESET="general"
fi

# ── Step 3: Confirm ───────────────────────────────────────────────────────────

if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo ""
  info "This will install Claude Code Mastery to $CLAUDE_DIR"
  info "Existing configs will be backed up as .bak files"
  echo ""
  read -rp "  Continue? [Y/n] " REPLY
  REPLY=${REPLY:-Y}
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "  Aborted."
    exit 0
  fi
  echo ""
fi

# ── Step 4: Create directory structure ────────────────────────────────────────

info "Setting up directory structure..."

if ! do_or_dry "create $CLAUDE_DIR/{skills,hooks}"; then
  mkdir -p "$CLAUDE_DIR/skills"
  mkdir -p "$CLAUDE_DIR/hooks"
fi

success "Directory structure ready"

# ── Step 5: Install config files ──────────────────────────────────────────────

info "Installing configuration files..."

install_file "$REPO_DIR/configs/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md (global rules)"
install_file "$REPO_DIR/configs/settings.json" "$CLAUDE_DIR/settings.json" "settings.json (hooks + permissions)"
install_file "$REPO_DIR/configs/settings.local.json" "$CLAUDE_DIR/settings.local.json" "settings.local.json (MCP auto-enable)"

# ── Step 6: Install custom skills ─────────────────────────────────────────────

info "Installing custom skills..."

install_file "$REPO_DIR/skills/architect-review.md" "$CLAUDE_DIR/skills/architect-review.md" "skill: architect-review"
install_file "$REPO_DIR/skills/context-guardian.md" "$CLAUDE_DIR/skills/context-guardian.md" "skill: context-guardian"
install_file "$REPO_DIR/skills/production-audit.md" "$CLAUDE_DIR/skills/production-audit.md" "skill: production-audit"

# ── Step 7: Install hooks ─────────────────────────────────────────────────────

info "Installing hooks..."

install_file "$REPO_DIR/hooks/auto-update-plugins.sh" "$CLAUDE_DIR/hooks/auto-update-plugins.sh" "hook: auto-update-plugins"
install_file "$REPO_DIR/hooks/pre-compact-save.sh" "$CLAUDE_DIR/hooks/pre-compact-save.sh" "hook: pre-compact-save"

if ! do_or_dry "chmod +x hooks"; then
  chmod +x "$CLAUDE_DIR/hooks/auto-update-plugins.sh"
  chmod +x "$CLAUDE_DIR/hooks/pre-compact-save.sh"
fi

# ── Step 8: Install MEMORY.md template ────────────────────────────────────────

info "Installing auto-memory template..."

# Create a default project memory directory
DEFAULT_MEMORY_DIR="$CLAUDE_DIR/projects/-default/memory"
if ! do_or_dry "create $DEFAULT_MEMORY_DIR"; then
  mkdir -p "$DEFAULT_MEMORY_DIR"
fi

install_file "$REPO_DIR/configs/MEMORY.md" "$DEFAULT_MEMORY_DIR/MEMORY.md" "MEMORY.md (auto-memory template)"

# ── Step 9: Install plugin marketplaces ───────────────────────────────────────

if [ "$SKIP_PLUGINS" = true ]; then
  info "Skipping plugin installation (--skip-plugins)"
else
  info "Installing plugin marketplaces..."

  ALL_MARKETPLACES=(
    "obra/superpowers-marketplace"
    "trailofbits/skills"
    "NeoLabHQ/context-engineering-kit"
    "alissonlinneker/shield-claude-skill"
  )

  # Filter marketplaces if --plugins was specified
  if [ -n "$SELECTED_PLUGINS" ]; then
    MARKETPLACES=()
    IFS=',' read -ra SELECTED <<< "$SELECTED_PLUGINS"
    for sel in "${SELECTED[@]}"; do
      sel=$(echo "$sel" | tr -d ' ')
      for mp in "${ALL_MARKETPLACES[@]}"; do
        if echo "$mp" | grep -qi "$sel"; then
          MARKETPLACES+=("$mp")
        fi
      done
    done
    info "Installing selected marketplaces: ${MARKETPLACES[*]}"
  else
    MARKETPLACES=("${ALL_MARKETPLACES[@]}")
  fi

  for marketplace in "${MARKETPLACES[@]}"; do
    if do_or_dry "claude plugin marketplace add $marketplace"; then continue; fi

    info "Adding marketplace: $marketplace"
    if claude plugin marketplace add "$marketplace" 2>/dev/null; then
      success "Marketplace: $marketplace"
    else
      warn "Could not add marketplace: $marketplace (you can add it manually later)"
    fi
  done

  # ── Step 10: Install plugins ──────────────────────────────────────────────────

  info "Installing plugins from marketplaces..."

  PLUGINS=(
    "superpowers@superpowers-marketplace"
    "shield@shield-security"
    "differential-review@trailofbits"
    "static-analysis@trailofbits"
    "audit-context-building@trailofbits"
    "supply-chain-risk-auditor@trailofbits"
    "agentic-actions-auditor@trailofbits"
    "sdd@context-engineering-kit"
    "reflexion@context-engineering-kit"
    "code-review@context-engineering-kit"
    "kaizen@context-engineering-kit"
  )

  for plugin in "${PLUGINS[@]}"; do
    if do_or_dry "claude plugin install $plugin"; then continue; fi

    if claude plugin install "$plugin" 2>/dev/null; then
      success "Plugin: $plugin"
    else
      warn "Could not install plugin: $plugin (you can install it manually later)"
    fi
  done
fi

# ── Step 11: Add shell function ───────────────────────────────────────────────

info "Installing shell launcher function..."

# Determine which shell function to use
SHELL_FUNC_FILE=""
case "$(basename "$SHELL_CONFIG")" in
  .zshrc)  SHELL_FUNC_FILE="$REPO_DIR/shell/claude_code.zsh" ;;
  .bashrc) SHELL_FUNC_FILE="$REPO_DIR/shell/claude_code.bash" ;;
esac

if [ -n "$SHELL_FUNC_FILE" ] && [ -f "$SHELL_FUNC_FILE" ]; then
  # Check if already installed (idempotent)
  if grep -qF "$GUARD_START" "$SHELL_CONFIG" 2>/dev/null; then
    info "Shell function already installed in $SHELL_CONFIG (skipping)"
  else
    if ! do_or_dry "append shell function to $SHELL_CONFIG"; then
      {
        echo ""
        echo "$GUARD_START"
        cat "$SHELL_FUNC_FILE"
        echo "$GUARD_END"
      } >> "$SHELL_CONFIG"
      success "Shell function added to $SHELL_CONFIG"
    fi
  fi
else
  warn "Could not determine shell function file for $SHELL_CONFIG"
fi

# ── Step 12: Handle global .mcp.json ──────────────────────────────────────────

if [ -f "$HOME/.mcp.json" ]; then
  warn "Found global ~/.mcp.json — Memory Bank should be per-project only"
  backup_file "$HOME/.mcp.json"

  if [ "$FORCE" = true ]; then
    if ! do_or_dry "remove ~/.mcp.json (backed up)"; then
      rm "$HOME/.mcp.json"
      success "Removed global ~/.mcp.json (backup saved)"
    fi
  else
    if [ "$DRY_RUN" = false ]; then
      read -rp "  Remove global ~/.mcp.json? (backed up) [Y/n] " REPLY
      REPLY=${REPLY:-Y}
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        rm "$HOME/.mcp.json"
        success "Removed global ~/.mcp.json (backup saved)"
      else
        info "Keeping global ~/.mcp.json (may conflict with per-project config)"
      fi
    fi
  fi
fi

# ── Step 13: Apply language ────────────────────────────────────────────────────

if [ "$LANG_CODE" != "en" ]; then
  info "Applying hook language: $LANG_CODE"
  if [ -f "$REPO_DIR/scripts/apply-language.sh" ] && ! do_or_dry "apply language $LANG_CODE"; then
    bash "$REPO_DIR/scripts/apply-language.sh" "$LANG_CODE" 2>/dev/null && \
      success "Hook language: $LANG_CODE" || \
      warn "Could not apply language $LANG_CODE (you can run scripts/apply-language.sh later)"
  fi
fi

# ── Step 14: Apply preset ─────────────────────────────────────────────────────

if [ "$PRESET" != "general" ]; then
  info "Applying project preset: $PRESET"
  if [ -f "$REPO_DIR/scripts/apply-preset.sh" ] && ! do_or_dry "apply preset $PRESET"; then
    bash "$REPO_DIR/scripts/apply-preset.sh" "$PRESET" 2>/dev/null && \
      success "Preset: $PRESET" || \
      warn "Could not apply preset $PRESET (you can run scripts/apply-preset.sh later)"
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Installation Complete!                          │${NC}"
echo -e "${BOLD}└──────────────────────────────────────────────────┘${NC}"
echo ""
echo "  Installed:"
echo -e "    ${GREEN}✓${NC} Global rules      → ~/.claude/CLAUDE.md"
echo -e "    ${GREEN}✓${NC} Settings + hooks  → ~/.claude/settings.json"
echo -e "    ${GREEN}✓${NC} MCP auto-enable   → ~/.claude/settings.local.json"
echo -e "    ${GREEN}✓${NC} Custom skills (3) → ~/.claude/skills/"
echo -e "    ${GREEN}✓${NC} Auto-update hook  → ~/.claude/hooks/"
echo -e "    ${GREEN}✓${NC} Memory template   → ~/.claude/projects/"
echo -e "    ${GREEN}✓${NC} Shell launcher    → $SHELL_CONFIG"
if [ "$LANG_CODE" != "en" ]; then
  echo -e "    ${GREEN}✓${NC} Hook language     → $LANG_CODE"
fi
if [ "$PRESET" != "general" ]; then
  echo -e "    ${GREEN}✓${NC} Project preset    → $PRESET"
fi
echo ""
echo "  Next steps:"
echo "    1. Reload your shell:  source $SHELL_CONFIG"
echo "    2. Navigate to a project directory"
echo "    3. Run: claude"
echo ""
echo "  The launcher will auto-configure Memory Bank, .gitignore,"
echo "  and session logging for each project on first run."
echo ""
echo "  To uninstall: ./uninstall.sh"
echo ""
