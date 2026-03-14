#!/usr/bin/env bash
# Claude Code Mastery — Apply Language to Hooks
# Usage: ./scripts/apply-language.sh [lang]
# Example: ./scripts/apply-language.sh pt-BR

set -euo pipefail

LANG_CODE="${1:-en}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LANG_FILE="$REPO_DIR/configs/i18n/${LANG_CODE}.json"
EN_FILE="$REPO_DIR/configs/i18n/en.json"
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

if [ ! -f "$EN_FILE" ]; then
  echo "Error: English base file not found: $EN_FILE"
  exit 1
fi

# Backup current settings
cp "$SETTINGS" "${SETTINGS}.bak"

# Use python3 to do find/replace of English strings with translated strings
export LANG_FILE EN_FILE SETTINGS
python3 << 'PYEOF'
import json, os

lang_file = os.environ["LANG_FILE"]
en_file = os.environ["EN_FILE"]
settings_file = os.environ["SETTINGS"]

with open(en_file) as f:
    en = json.load(f)

with open(lang_file) as f:
    translated = json.load(f)

with open(settings_file) as f:
    content = f.read()

# Replace each English string with its translation
for key in en:
    if key in translated and en[key] != translated[key]:
        content = content.replace(en[key], translated[key])

with open(settings_file, 'w') as f:
    f.write(content)

# Verify the result is still valid JSON
json.loads(content)

lang_code = os.path.splitext(os.path.basename(lang_file))[0]
print(f"Language set to: {lang_code}")
PYEOF

echo "Hook messages updated to: $LANG_CODE"
echo "Backup saved: ${SETTINGS}.bak"
