#!/usr/bin/env bash
# Claude Code Mastery — Apply Project Preset
# Usage: ./scripts/apply-preset.sh [preset]
# Example: ./scripts/apply-preset.sh node

set -euo pipefail

PRESET="${1:-general}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PRESET_FILE="$REPO_DIR/configs/presets/${PRESET}.json"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$PRESET_FILE" ]; then
  echo "Error: Preset not found: $PRESET_FILE"
  echo "Available presets:"
  ls "$REPO_DIR/configs/presets/" | sed 's/.json$//'
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "Error: Settings file not found: $SETTINGS"
  echo "Run install.sh first."
  exit 1
fi

# Backup
cp "$SETTINGS" "${SETTINGS}.bak"

# Merge preset permissions using python3
python3 << PYEOF
import json, os

preset_file = "$PRESET_FILE"
settings_file = "$SETTINGS"

with open(preset_file) as f:
    preset = json.load(f)

with open(settings_file) as f:
    settings = json.load(f)

# Get extra permissions from preset
extra_allow = preset.get("permissions", {}).get("allow", [])

# Merge (add extras that don't already exist)
current_allow = settings.get("permissions", {}).get("allow", [])
for perm in extra_allow:
    if perm not in current_allow:
        current_allow.append(perm)

settings["permissions"]["allow"] = current_allow

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)

name = preset.get("name", "$PRESET")
desc = preset.get("description", "")
added = len(extra_allow)
print(f"Preset applied: {name}")
print(f"Description: {desc}")
print(f"Extra permissions added: {added}")
PYEOF

echo "Backup saved: ${SETTINGS}.bak"
