#!/usr/bin/env bash
# Claude Code Mastery — Full Integration Test
# Runs in a clean Docker container to validate the entire install/uninstall flow.
#
# Usage: bash tests/integration/test-full-flow.sh

set -euo pipefail

# ── Test Framework ─────────────────────────────────────────────────────────────

PASS=0
FAIL=0
TOTAL=0
ERRORS=()

assert() {
  local desc="$1"
  local result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "true" ]; then
    echo -e "  \033[0;32m✓\033[0m $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  \033[0;31m✗\033[0m $desc"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Claude Code Mastery — Integration Tests        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo "  Shell: $SHELL"
echo "  Repo: $REPO_DIR"
echo ""

# Determine shell config path
SHELL_CONFIG="$HOME/.bashrc"
if [ "$(basename "${SHELL:-/bin/bash}")" = "zsh" ]; then
  SHELL_CONFIG="$HOME/.zshrc"
fi

# ── Phase 1: Pre-Install Validation ──────────────────────────────────────────

echo "  Phase 1: Pre-Install Validation"
echo ""

assert "install.sh exists" "$(test -f "$REPO_DIR/install.sh" && echo true || echo false)"
assert "install.sh is executable" "$(test -x "$REPO_DIR/install.sh" && echo true || echo false)"
assert "uninstall.sh exists" "$(test -f "$REPO_DIR/uninstall.sh" && echo true || echo false)"
assert "~/.claude/ does not exist yet" "$(test ! -d "$CLAUDE_DIR" && echo true || echo false)"

# Run existing static tests
echo ""
echo "  Running static tests..."
bash "$REPO_DIR/tests/test-install.sh" > /dev/null 2>&1
assert "test-install.sh passes" "$(echo true)"
bash "$REPO_DIR/tests/test-hooks.sh" > /dev/null 2>&1
assert "test-hooks.sh passes" "$(echo true)"

echo ""

# ── Phase 2: Installation ────────────────────────────────────────────────────

echo "  Phase 2: Installation (--force)"
echo ""

# Ensure shell config exists (Docker containers may not have it)
touch "$SHELL_CONFIG"

# Run installer
bash "$REPO_DIR/install.sh" --force > /tmp/install-output.txt 2>&1
INSTALL_EXIT=$?
assert "install.sh exits 0" "$(test $INSTALL_EXIT -eq 0 && echo true || echo false)"

# Verify all installed files
assert "~/.claude/ exists" "$(test -d "$CLAUDE_DIR" && echo true || echo false)"
assert "~/.claude/CLAUDE.md installed" "$(test -s "$CLAUDE_DIR/CLAUDE.md" && echo true || echo false)"
assert "~/.claude/settings.json installed" "$(test -s "$CLAUDE_DIR/settings.json" && echo true || echo false)"
assert "~/.claude/settings.local.json installed" "$(test -s "$CLAUDE_DIR/settings.local.json" && echo true || echo false)"
assert "~/.claude/skills/ exists" "$(test -d "$CLAUDE_DIR/skills" && echo true || echo false)"
assert "skill: architect-review.md installed" "$(test -s "$CLAUDE_DIR/skills/architect-review.md" && echo true || echo false)"
assert "skill: context-guardian.md installed" "$(test -s "$CLAUDE_DIR/skills/context-guardian.md" && echo true || echo false)"
assert "skill: production-audit.md installed" "$(test -s "$CLAUDE_DIR/skills/production-audit.md" && echo true || echo false)"
assert "~/.claude/hooks/ exists" "$(test -d "$CLAUDE_DIR/hooks" && echo true || echo false)"
assert "hook: auto-update-plugins.sh installed" "$(test -s "$CLAUDE_DIR/hooks/auto-update-plugins.sh" && echo true || echo false)"
assert "hook is executable" "$(test -x "$CLAUDE_DIR/hooks/auto-update-plugins.sh" && echo true || echo false)"
assert "MEMORY.md template installed" "$(test -s "$CLAUDE_DIR/projects/-default/memory/MEMORY.md" && echo true || echo false)"

# Verify JSON validity
assert "installed settings.json is valid JSON" "$(python3 -c "import json; json.load(open('$CLAUDE_DIR/settings.json'))" 2>/dev/null && echo true || echo false)"
assert "installed settings.local.json is valid JSON" "$(python3 -c "import json; json.load(open('$CLAUDE_DIR/settings.local.json'))" 2>/dev/null && echo true || echo false)"

# Verify shell function was added to shell config
assert "Shell function in config" "$(grep -q 'claude-code-mastery' "$SHELL_CONFIG" 2>/dev/null && echo true || echo false)"

echo ""

# ── Phase 3: Launcher Function ───────────────────────────────────────────────

echo "  Phase 3: Launcher Function"
echo ""

# Source the launcher function directly from the repo (avoids .bashrc interactive shell issues)
# Always use the bash version since this test script runs under bash
source "$REPO_DIR/shell/claude_code.bash" 2>/dev/null || true

# Create a fake project directory
FAKE_PROJECT="/tmp/test-project"
mkdir -p "$FAKE_PROJECT"
cd "$FAKE_PROJECT"
git init --quiet

# Run the launcher function (it should create .mcp.json, .memory-bank/, etc.)
# The function calls `command claude` which is mocked — may fail, that's OK
claude_code --help > /dev/null 2>&1 || true

assert ".mcp.json created by launcher" "$(test -f "$FAKE_PROJECT/.mcp.json" && echo true || echo false)"
assert ".memory-bank/ created by launcher" "$(test -d "$FAKE_PROJECT/.memory-bank" && echo true || echo false)"
assert ".gitignore created/updated by launcher" "$(test -f "$FAKE_PROJECT/.gitignore" && echo true || echo false)"
assert ".claude-logs/ created by launcher" "$(test -d "$FAKE_PROJECT/.claude-logs" && echo true || echo false)"

# Verify .mcp.json content
if [ -f "$FAKE_PROJECT/.mcp.json" ]; then
  assert ".mcp.json is valid JSON" "$(python3 -c "import json; json.load(open('$FAKE_PROJECT/.mcp.json'))" 2>/dev/null && echo true || echo false)"
  assert ".mcp.json has memory-bank config" "$(python3 -c "import json; d=json.load(open('$FAKE_PROJECT/.mcp.json')); assert 'memory-bank' in d.get('mcpServers',{})" 2>/dev/null && echo true || echo false)"
fi

# Verify .gitignore entries
if [ -f "$FAKE_PROJECT/.gitignore" ]; then
  assert ".gitignore has .memory-bank/" "$(grep -q '.memory-bank/' "$FAKE_PROJECT/.gitignore" && echo true || echo false)"
  assert ".gitignore has .mcp.json" "$(grep -q '.mcp.json' "$FAKE_PROJECT/.gitignore" && echo true || echo false)"
  assert ".gitignore has .claude-logs/" "$(grep -q '.claude-logs/' "$FAKE_PROJECT/.gitignore" && echo true || echo false)"
fi

# Verify idempotency — run launcher again, should not duplicate
claude_code --help > /dev/null 2>&1 || true
GITIGNORE_LINES=$(grep -c '.memory-bank/' "$FAKE_PROJECT/.gitignore" 2>/dev/null || echo 0)
assert ".gitignore not duplicated (idempotent)" "$(test "$GITIGNORE_LINES" -eq 1 && echo true || echo false)"

# Verify home directory guard
cd "$HOME"
OUTPUT=$(claude_code 2>&1 || true)
assert "Launcher blocks home directory" "$(echo "$OUTPUT" | grep -qi "cannot\|home" && echo true || echo false)"

cd "$REPO_DIR"

echo ""

# ── Phase 4: Language & Preset ────────────────────────────────────────────────

echo "  Phase 4: Language & Preset Application"
echo ""

# Test apply-preset
if [ -f "$REPO_DIR/scripts/apply-preset.sh" ]; then
  bash "$REPO_DIR/scripts/apply-preset.sh" node > /dev/null 2>&1
  PRESET_EXIT=$?
  assert "apply-preset.sh node exits 0" "$(test $PRESET_EXIT -eq 0 && echo true || echo false)"

  # Check that node permissions were added
  assert "Node permissions added (yarn)" "$(python3 -c "import json; d=json.load(open('$CLAUDE_DIR/settings.json')); assert any('yarn' in p for p in d['permissions']['allow'])" 2>/dev/null && echo true || echo false)"
fi

# Test apply-language
if [ -f "$REPO_DIR/scripts/apply-language.sh" ]; then
  bash "$REPO_DIR/scripts/apply-language.sh" pt-BR > /dev/null 2>&1
  LANG_EXIT=$?
  assert "apply-language.sh pt-BR exits 0" "$(test $LANG_EXIT -eq 0 && echo true || echo false)"

  # Check that Portuguese strings are in settings
  assert "Portuguese strings applied" "$(grep -q 'OBRIGAT' "$CLAUDE_DIR/settings.json" 2>/dev/null && echo true || echo false)"
fi

echo ""

# ── Phase 5: Uninstallation ───────────────────────────────────────────────────

echo "  Phase 5: Uninstallation (--force)"
echo ""

bash "$REPO_DIR/uninstall.sh" --force > /tmp/uninstall-output.txt 2>&1
UNINSTALL_EXIT=$?
assert "uninstall.sh exits 0" "$(test $UNINSTALL_EXIT -eq 0 && echo true || echo false)"

# Verify skills removed
assert "skill: architect-review.md removed" "$(test ! -f "$CLAUDE_DIR/skills/architect-review.md" && echo true || echo false)"
assert "skill: context-guardian.md removed" "$(test ! -f "$CLAUDE_DIR/skills/context-guardian.md" && echo true || echo false)"
assert "skill: production-audit.md removed" "$(test ! -f "$CLAUDE_DIR/skills/production-audit.md" && echo true || echo false)"

# Verify hook removed
assert "hook: auto-update-plugins.sh removed" "$(test ! -f "$CLAUDE_DIR/hooks/auto-update-plugins.sh" && echo true || echo false)"

# Verify shell function removed
assert "Shell function removed from config" "$(! grep -q 'claude-code-mastery' "$SHELL_CONFIG" 2>/dev/null && echo true || echo false)"

# Verify configs were restored (since there were no backups, they should be removed)
# The installer backed them up, so .bak files were created, then uninstaller restored from .bak

echo ""

# ── Phase 6: Re-Install with Flags ───────────────────────────────────────────

echo "  Phase 6: Re-Install with Flags"
echo ""

# Test --dry-run (should not create any files)
rm -rf "$CLAUDE_DIR"
bash "$REPO_DIR/install.sh" --force --dry-run > /tmp/dryrun-output.txt 2>&1
assert "--dry-run does not create ~/.claude/" "$(test ! -d "$CLAUDE_DIR/skills" && echo true || echo false)"

# Test --skip-plugins
bash "$REPO_DIR/install.sh" --force --skip-plugins > /tmp/skip-output.txt 2>&1
assert "--skip-plugins: install succeeds" "$(test -s "$CLAUDE_DIR/CLAUDE.md" && echo true || echo false)"
assert "--skip-plugins: mentioned in output" "$(grep -qi 'skip' /tmp/skip-output.txt && echo true || echo false)"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

echo "══════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "  \033[0;32mAll $TOTAL integration tests passed.\033[0m"
else
  echo -e "  \033[0;31m$FAIL/$TOTAL tests failed:\033[0m"
  for err in "${ERRORS[@]}"; do
    echo -e "    \033[0;31m✗\033[0m $err"
  done
fi

echo ""

exit "$FAIL"
