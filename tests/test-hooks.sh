#!/usr/bin/env bash
# Claude Code Mastery — Hook Validation Test Suite
# Validates that all hooks in settings.json are correctly configured.
#
# Usage: bash tests/test-hooks.sh

set -euo pipefail

# ── Test Framework ─────────────────────────────────────────────────────────────

PASS=0
FAIL=0
TOTAL=0
ERRORS=()

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$REPO_DIR/configs/settings.json"

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

json_has_key() {
  local key="$1"
  python3 -c "
import json, sys
data = json.load(open('$SETTINGS'))
keys = '$key'.split('.')
obj = data
for k in keys:
    if isinstance(obj, dict) and k in obj:
        obj = obj[k]
    else:
        sys.exit(1)
" 2>/dev/null && echo "true" || echo "false"
}

json_value() {
  local key="$1"
  python3 -c "
import json
data = json.load(open('$SETTINGS'))
keys = '$key'.split('.')
obj = data
for k in keys:
    obj = obj[k]
print(json.dumps(obj))
" 2>/dev/null || echo "null"
}

# ── Tests ──────────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Claude Code Mastery — Hook Validation Tests    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Prerequisites ─────────────────────────────────────────────────────────────

echo "  Prerequisites:"

assert "settings.json exists" "$( [ -f "$SETTINGS" ] && echo true || echo false )"

if [ ! -f "$SETTINGS" ]; then
  echo ""
  echo -e "  \033[0;31mCannot continue without settings.json\033[0m"
  exit 1
fi

valid_json="false"
if python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null; then
  valid_json="true"
fi
assert "settings.json is valid JSON" "$valid_json"

echo ""

# ── Hook Events ───────────────────────────────────────────────────────────────

echo "  Hook Events (6 required):"

HOOK_EVENTS=("SessionStart" "PreToolUse" "PreCompact" "UserPromptSubmit" "Stop" "TaskCompleted")

for event in "${HOOK_EVENTS[@]}"; do
  assert "hooks.$event exists" "$(json_has_key "hooks.$event")"
done

echo ""

# ── SessionStart Matchers ─────────────────────────────────────────────────────

echo "  SessionStart Matchers (3 required):"

# Check for startup, empty, and compact matchers
MATCHERS=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
matchers = [h.get('matcher', '') for h in data.get('hooks', {}).get('SessionStart', [])]
print('|'.join(matchers))
" 2>/dev/null || echo "")

has_startup="false"
if echo "$MATCHERS" | grep -q "startup"; then
  has_startup="true"
fi
assert "SessionStart has 'startup' matcher" "$has_startup"

has_default="false"
if echo "$MATCHERS" | grep -qE '\|\||\|$|^\|'; then
  has_default="true"
fi
# Alternative check: count matchers
MATCHER_COUNT=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
matchers = [h.get('matcher', '') for h in data.get('hooks', {}).get('SessionStart', [])]
print(len([m for m in matchers if m == '']))
" 2>/dev/null || echo "0")
if [ "$MATCHER_COUNT" -gt 0 ]; then
  has_default="true"
fi
assert "SessionStart has default (empty) matcher" "$has_default"

has_compact="false"
if echo "$MATCHERS" | grep -q "compact"; then
  has_compact="true"
fi
assert "SessionStart has 'compact' matcher" "$has_compact"

echo ""

# ── Hook Commands ─────────────────────────────────────────────────────────────

echo "  Hook Commands:"

# Verify each hook has a command
for event in "${HOOK_EVENTS[@]}"; do
  has_command=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
hooks = data.get('hooks', {}).get('$event', [])
for h in hooks:
    for sub in h.get('hooks', []):
        if sub.get('command', ''):
            print('true')
            exit()
print('false')
" 2>/dev/null || echo "false")
  assert "hooks.$event has at least one command" "$has_command"
done

echo ""

# ── PreToolUse Security ───────────────────────────────────────────────────────

echo "  PreToolUse Security:"

assert "PreToolUse targets Bash commands" "$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
hooks = data.get('hooks', {}).get('PreToolUse', [])
for h in hooks:
    if h.get('matcher') == 'Bash':
        print('true')
        exit()
print('false')
" 2>/dev/null || echo "false")"

# Check deny patterns in the hook command
pretool_cmd=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
hooks = data.get('hooks', {}).get('PreToolUse', [])
for h in hooks:
    for sub in h.get('hooks', []):
        print(sub.get('command', ''))
" 2>/dev/null || echo "")

for pattern in "rm -rf" "sudo rm" "chmod 777" "force"; do
  has_pattern="false"
  if echo "$pretool_cmd" | grep -q "$pattern"; then
    has_pattern="true"
  fi
  assert "PreToolUse blocks '$pattern'" "$has_pattern"
done

assert "PreToolUse returns deny decision" "$(echo "$pretool_cmd" | grep -q "permissionDecision.*deny" && echo true || echo false)"

echo ""

# ── Hook Timeouts ─────────────────────────────────────────────────────────────

echo "  Hook Timeouts:"

# SessionStart hooks should have timeouts
has_timeouts=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
hooks = data.get('hooks', {}).get('SessionStart', [])
for h in hooks:
    for sub in h.get('hooks', []):
        if 'timeout' in sub:
            print('true')
            exit()
print('false')
" 2>/dev/null || echo "false")
assert "SessionStart hooks have timeout values" "$has_timeouts"

# PreCompact should have timeout
has_precompact_timeout=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
hooks = data.get('hooks', {}).get('PreCompact', [])
for h in hooks:
    for sub in h.get('hooks', []):
        if 'timeout' in sub:
            print('true')
            exit()
print('false')
" 2>/dev/null || echo "false")
assert "PreCompact hook has timeout" "$has_precompact_timeout"

echo ""

# ── Permissions ───────────────────────────────────────────────────────────────

echo "  Permissions:"

assert "permissions.allow exists" "$(json_has_key "permissions.allow")"
assert "permissions.deny exists" "$(json_has_key "permissions.deny")"

# Check allow has common safe commands
for cmd in "git" "npm" "node" "ls" "cat"; do
  has_cmd=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
allow = data.get('permissions', {}).get('allow', [])
print('true' if any('$cmd' in a for a in allow) else 'false')
" 2>/dev/null || echo "false")
  assert "permissions.allow includes '$cmd'" "$has_cmd"
done

# Check deny has dangerous patterns
for deny_pattern in "rm -rf /" "rm -rf ~" "sudo rm" "push --force"; do
  has_deny=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
deny = data.get('permissions', {}).get('deny', [])
print('true' if any('$deny_pattern' in d for d in deny) else 'false')
" 2>/dev/null || echo "false")
  assert "permissions.deny blocks '$deny_pattern'" "$has_deny"
done

echo ""

# ── Plugins ───────────────────────────────────────────────────────────────────

echo "  Plugin Configuration:"

assert "enabledPlugins exists" "$(json_has_key "enabledPlugins")"
assert "extraKnownMarketplaces exists" "$(json_has_key "extraKnownMarketplaces")"

# Check key plugins are enabled
EXPECTED_PLUGINS=("superpowers" "shield" "differential-review" "static-analysis" "sdd" "kaizen")
for plugin in "${EXPECTED_PLUGINS[@]}"; do
  has_plugin=$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
plugins = data.get('enabledPlugins', {})
print('true' if any('$plugin' in k for k in plugins) else 'false')
" 2>/dev/null || echo "false")
  assert "Plugin '$plugin' is enabled" "$has_plugin"
done

echo ""

# ── Environment ───────────────────────────────────────────────────────────────

echo "  Environment:"

assert "env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE exists" "$(json_has_key "env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE")"
assert "attribution.commit is empty (no AI)" "$(python3 -c "
import json
data = json.load(open('$SETTINGS'))
print('true' if data.get('attribution', {}).get('commit', 'x') == '' else 'false')
" 2>/dev/null || echo "false")"

echo ""

# ── Auto-Update Hook File ────────────────────────────────────────────────────

echo "  Auto-Update Hook:"

HOOK_FILE="$REPO_DIR/hooks/auto-update-plugins.sh"

if [ -f "$HOOK_FILE" ]; then
  assert "Hook file passes bash syntax check" "$(bash -n "$HOOK_FILE" 2>/dev/null && echo true || echo false)"
  assert "Hook uses lock file" "$(grep -q "LOCK_FILE" "$HOOK_FILE" && echo true || echo false)"
  assert "Hook has cache/throttle" "$(grep -q "UPDATE_INTERVAL\|CACHE_FILE" "$HOOK_FILE" && echo true || echo false)"
  assert "Hook has cleanup trap" "$(grep -q "trap" "$HOOK_FILE" && echo true || echo false)"
else
  assert "Hook file exists at hooks/auto-update-plugins.sh" "false"
fi

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
