#!/usr/bin/env bash
# Claude Code Mastery — Apply Language to Hooks
# Usage: ./scripts/apply-language.sh [lang]
# Example: ./scripts/apply-language.sh pt-BR

set -euo pipefail

LANG_CODE="${1:-en}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LANG_FILE="$REPO_DIR/configs/i18n/${LANG_CODE}.json"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$LANG_FILE" ]; then
  echo "Error: Language file not found: $LANG_FILE"
  echo "Available languages:"
  ls "$REPO_DIR/configs/i18n/" | sed 's/.json$//'
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "Error: Settings file not found: $SETTINGS"
  echo "Run install.sh first."
  exit 1
fi

# Backup current settings
cp "$SETTINGS" "${SETTINGS}.bak"

# Use python3 to rebuild settings.json with translated hook strings
export REPO_DIR LANG_CODE SETTINGS
python3 << PYEOF
import json, os

lang_code = os.environ.get("LANG_CODE", "en")
repo_dir = os.environ.get("REPO_DIR", ".")
lang_file = os.path.join(repo_dir, "configs", "i18n", f"{lang_code}.json")
settings_file = os.environ.get("SETTINGS", os.path.join(os.path.expanduser("~"), ".claude", "settings.json"))

with open(lang_file) as f:
    strings = json.load(f)

with open(settings_file) as f:
    settings = json.load(f)

# Rebuild SessionStart default hook command with translated strings
session_default_cmd = (
    f"echo '{strings['session_context_header']}' && "
    f"if [ -f CLAUDE.md ]; then CMD_SIZE=$(stat -f%z CLAUDE.md 2>/dev/null || stat -c%s CLAUDE.md 2>/dev/null || echo 0); echo \"{strings['claude_md_status'].replace('{size}', '${CMD_SIZE}')}\"; fi && "
    f"if [ -d .memory-bank ]; then "
    f"MB_COUNT=$(find .memory-bank -name '*.md' -type f 2>/dev/null | head -50 | wc -l | tr -d ' '); "
    f"echo \"{strings['memory_bank_count'].replace('{count}', '$MB_COUNT')}\"; "
    f"if [ \"$MB_COUNT\" -gt 0 ] 2>/dev/null; then "
    f"find .memory-bank -name '*.md' -type f 2>/dev/null | head -20 | while read f; do echo \"  - $(basename $f)\"; done; "
    f"echo '{strings['memory_bank_required']}'; "
    f"else echo '{strings['memory_bank_empty']}'; fi; "
    f"else echo '{strings['memory_bank_not_configured']}'; fi && "
    f"echo \"{strings['project_label'].replace('{name}', '$(basename $(pwd))')}\" && "
    f"if git rev-parse --git-dir > /dev/null 2>&1; then "
    f"echo \"{strings['branch_label'].replace('{branch}', '$(git branch --show-current 2>/dev/null)')}\" && "
    f"echo \"{strings['modified_label'].replace('{count}', '$(git status --short 2>/dev/null | wc -l | tr -d \" \")')}\" && "
    f"echo \"{strings['last_commit_label'].replace('{commit}', '$(git log --oneline -1 2>/dev/null)')}\"; fi && "
    f"echo '{strings['session_context_footer']}'"
)

# Rebuild SessionStart compact hook
compact_cmd = (
    f"echo '{strings['compacted_header']}' && "
    f"echo '{strings['compacted_step_1']}' && "
    f"echo '{strings['compacted_step_2']}' && "
    f"echo '{strings['compacted_step_3']}' && "
    f"echo '{strings['compacted_step_4']}' && "
    f"echo '{strings['compacted_step_5']}' && "
    f"echo '{strings['compacted_reminder']}' && "
    f"if [ -d .memory-bank ]; then echo '{strings['compacted_memory_bank_header']}'; "
    f"find .memory-bank -name '*.md' -type f 2>/dev/null | head -20 | while read f; do echo \"  - $(basename $f)\"; done; fi && "
    f"echo \"{strings['project_label'].replace('{name}', '$(basename $(pwd))')}\" && "
    f"if git rev-parse --git-dir > /dev/null 2>&1; then "
    f"echo \"{strings['branch_label'].replace('{branch}', '$(git branch --show-current 2>/dev/null)')}\" && "
    f"echo \"{strings['last_commit_label'].replace('{commit}', '$(git log --oneline -1 2>/dev/null)')}\" && "
    f"echo '{strings['compacted_modified_files']}'; git diff --name-only 2>/dev/null | head -10; fi && "
    f"echo '{strings['compacted_footer']}'"
)

# Rebuild PreCompact hook
precompact_cmd = (
    f"echo '{strings['pre_compact_header']}' && "
    f"echo '{strings['pre_compact_required']}' && "
    f"echo '{strings['pre_compact_step_1']}' && "
    f"echo '{strings['pre_compact_step_2']}' && "
    f"echo '{strings['pre_compact_step_3']}' && "
    f"echo '{strings['pre_compact_step_4']}' && "
    f"echo '{strings['pre_compact_instruction']}' && "
    f"echo '{strings['pre_compact_warning']}' && "
    f"echo '{strings['pre_compact_footer']}'"
)

# Apply translations to hooks
for hook_group in settings.get("hooks", {}).get("SessionStart", []):
    if hook_group.get("matcher") == "":
        hook_group["hooks"][0]["command"] = session_default_cmd
    elif hook_group.get("matcher") == "compact":
        hook_group["hooks"][0]["command"] = compact_cmd

for hook_group in settings.get("hooks", {}).get("PreCompact", []):
    hook_group["hooks"][0]["command"] = precompact_cmd

for hook_group in settings.get("hooks", {}).get("UserPromptSubmit", []):
    hook_group["hooks"][0]["command"] = f"echo '{strings['prompt_reminder']}'"

for hook_group in settings.get("hooks", {}).get("Stop", []):
    hook_group["hooks"][0]["command"] = f"echo '{strings['stop_reminder']}'"

for hook_group in settings.get("hooks", {}).get("TaskCompleted", []):
    hook_group["hooks"][0]["command"] = f"echo '{strings['task_completed_reminder']}'"

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)

print(f"Language set to: {lang_code}")
PYEOF

echo "Hook messages updated to: $LANG_CODE"
echo "Backup saved: ${SETTINGS}.bak"
