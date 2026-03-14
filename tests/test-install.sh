#!/usr/bin/env bash
# Claude Code Mastery — Installation Test Suite
# Validates that all template files exist, are valid, and contain no personal data.
#
# Usage: bash tests/test-install.sh

set -euo pipefail

# ── Test Framework ─────────────────────────────────────────────────────────────

PASS=0
FAIL=0
TOTAL=0
ERRORS=()

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

file_exists() {
  [ -f "$REPO_DIR/$1" ] && echo "true" || echo "false"
}

file_not_empty() {
  [ -s "$REPO_DIR/$1" ] && echo "true" || echo "false"
}

# ── Tests ──────────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Claude Code Mastery — Installation Tests       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Config Templates ──────────────────────────────────────────────────────────

echo "  Config Templates:"

assert "configs/CLAUDE.md exists" "$(file_exists configs/CLAUDE.md)"
assert "configs/CLAUDE.md is not empty" "$(file_not_empty configs/CLAUDE.md)"
assert "configs/settings.json exists" "$(file_exists configs/settings.json)"
assert "configs/settings.json is not empty" "$(file_not_empty configs/settings.json)"
assert "configs/settings.local.json exists" "$(file_exists configs/settings.local.json)"
assert "configs/MEMORY.md exists" "$(file_exists configs/MEMORY.md)"
assert "configs/MEMORY.md is not empty" "$(file_not_empty configs/MEMORY.md)"

echo ""

# ── JSON Validation ───────────────────────────────────────────────────────────

echo "  JSON Validation:"

for json_file in configs/settings.json configs/settings.local.json; do
  if [ -f "$REPO_DIR/$json_file" ]; then
    result="false"
    if python3 -c "import json; json.load(open('$REPO_DIR/$json_file'))" 2>/dev/null; then
      result="true"
    fi
    assert "$json_file is valid JSON" "$result"
  else
    assert "$json_file is valid JSON" "false"
  fi
done

echo ""

# ── Skills ────────────────────────────────────────────────────────────────────

echo "  Custom Skills:"

SKILLS=("skills/architect-review.md" "skills/context-guardian.md" "skills/production-audit.md")

for skill in "${SKILLS[@]}"; do
  assert "$skill exists" "$(file_exists "$skill")"
  assert "$skill is not empty" "$(file_not_empty "$skill")"

  # Check frontmatter
  if [ -f "$REPO_DIR/$skill" ]; then
    has_frontmatter="false"
    if head -1 "$REPO_DIR/$skill" | grep -q "^---"; then
      has_frontmatter="true"
    fi
    assert "$skill has YAML frontmatter" "$has_frontmatter"

    has_name="false"
    if grep -q "^name:" "$REPO_DIR/$skill"; then
      has_name="true"
    fi
    assert "$skill has 'name' field" "$has_name"

    has_desc="false"
    if grep -q "^description:" "$REPO_DIR/$skill"; then
      has_desc="true"
    fi
    assert "$skill has 'description' field" "$has_desc"
  fi
done

echo ""

# ── Hooks ─────────────────────────────────────────────────────────────────────

echo "  Hooks:"

assert "hooks/auto-update-plugins.sh exists" "$(file_exists hooks/auto-update-plugins.sh)"
assert "hooks/auto-update-plugins.sh is not empty" "$(file_not_empty hooks/auto-update-plugins.sh)"

if [ -f "$REPO_DIR/hooks/auto-update-plugins.sh" ]; then
  syntax_ok="false"
  if bash -n "$REPO_DIR/hooks/auto-update-plugins.sh" 2>/dev/null; then
    syntax_ok="true"
  fi
  assert "hooks/auto-update-plugins.sh passes syntax check" "$syntax_ok"

  has_shebang="false"
  if head -1 "$REPO_DIR/hooks/auto-update-plugins.sh" | grep -q "^#!/"; then
    has_shebang="true"
  fi
  assert "hooks/auto-update-plugins.sh has shebang" "$has_shebang"
fi

echo ""

# ── Shell Functions ───────────────────────────────────────────────────────────

echo "  Shell Functions:"

SHELL_FILES=("shell/claude_code.zsh" "shell/claude_code.bash")

for shell_file in "${SHELL_FILES[@]}"; do
  assert "$shell_file exists" "$(file_exists "$shell_file")"
  assert "$shell_file is not empty" "$(file_not_empty "$shell_file")"

  if [ -f "$REPO_DIR/$shell_file" ]; then
    # Check for claude_code function definition
    has_func="false"
    if grep -q "claude_code()" "$REPO_DIR/$shell_file"; then
      has_func="true"
    fi
    assert "$shell_file defines claude_code()" "$has_func"

    # Check for alias
    has_alias="false"
    if grep -q "alias claude=" "$REPO_DIR/$shell_file"; then
      has_alias="true"
    fi
    assert "$shell_file defines claude alias" "$has_alias"
  fi
done

echo ""

# ── Installer / Uninstaller ───────────────────────────────────────────────────

echo "  Installer / Uninstaller:"

assert "install.sh exists" "$(file_exists install.sh)"
assert "uninstall.sh exists" "$(file_exists uninstall.sh)"

for script in install.sh uninstall.sh; do
  if [ -f "$REPO_DIR/$script" ]; then
    is_exec="false"
    if [ -x "$REPO_DIR/$script" ]; then
      is_exec="true"
    fi
    assert "$script is executable" "$is_exec"

    syntax_ok="false"
    if bash -n "$REPO_DIR/$script" 2>/dev/null; then
      syntax_ok="true"
    fi
    assert "$script passes syntax check" "$syntax_ok"
  fi
done

# Check guard markers are consistent
if [ -f "$REPO_DIR/install.sh" ] && [ -f "$REPO_DIR/uninstall.sh" ]; then
  install_guard=$(grep -c "claude-code-mastery" "$REPO_DIR/install.sh" || true)
  uninstall_guard=$(grep -c "claude-code-mastery" "$REPO_DIR/uninstall.sh" || true)
  guards_ok="false"
  if [ "$install_guard" -gt 0 ] && [ "$uninstall_guard" -gt 0 ]; then
    guards_ok="true"
  fi
  assert "Guard markers present in both install/uninstall" "$guards_ok"
fi

echo ""

# ── Documentation ─────────────────────────────────────────────────────────────

echo "  Documentation:"

assert "README.md exists" "$(file_exists README.md)"
assert "README.md is not empty" "$(file_not_empty README.md)"
assert "LICENSE exists" "$(file_exists LICENSE)"

DOCS=("docs/configuration.md" "docs/hooks.md" "docs/skills.md" "docs/memory-bank.md" "docs/troubleshooting.md" "docs/customization.md")

for doc in "${DOCS[@]}"; do
  assert "$doc exists" "$(file_exists "$doc")"
done

echo ""

# ── Personal Data Check ──────────────────────────────────────────────────────

echo "  Personal Data Check:"

# Scan all non-git files for personal data patterns
PERSONAL_DATA="false"
if grep -r --include="*.md" --include="*.json" --include="*.sh" --include="*.bash" --include="*.zsh" \
   -iE "(\/Users\/[a-z]|\/home\/[a-z]|@gmail\.com|@hotmail\.com|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,})" \
   --exclude-dir=.git --exclude-dir=.memory-bank --exclude-dir=docs/plans \
   "$REPO_DIR" 2>/dev/null | grep -vE "(github\.com/|example\.com|your-)" > /dev/null 2>&1; then
  PERSONAL_DATA="true"
fi

no_personal="true"
if [ "$PERSONAL_DATA" = "true" ]; then
  no_personal="false"
fi
assert "No personal data (paths, emails, API keys) in templates" "$no_personal"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

echo "══════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "  \033[0;32mAll $TOTAL tests passed.\033[0m"
else
  echo -e "  \033[0;31m$FAIL/$TOTAL tests failed:\033[0m"
  for err in "${ERRORS[@]}"; do
    echo -e "    \033[0;31m✗\033[0m $err"
  done
fi

echo ""

exit "$FAIL"
