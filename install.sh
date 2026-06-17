#!/usr/bin/env bash
# Manual installer for users not using the Claude Code plugin system.
# Copies the hooks + templates to ~/.claude and prints the settings.json snippet
# to paste. It does NOT silently mutate settings.json.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/plugins/obsidian-memory" && pwd)"
DEST="$HOME/.claude/obsidian-memory-standalone"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq / apt-get install jq)"; exit 1; }

mkdir -p "$DEST/hooks" "$DEST/templates"
cp "$SRC_DIR/hooks/obsidian-load.sh" "$DEST/hooks/"
cp "$SRC_DIR/hooks/obsidian-save.sh" "$DEST/hooks/"
cp "$SRC_DIR/templates/project_SUMMARY.md" "$DEST/templates/"
cp "$SRC_DIR/templates/project_note.md" "$DEST/templates/"
chmod +x "$DEST/hooks/"*.sh

echo "Installed hooks + templates to: $DEST"
echo
echo "Now add this to ~/.claude/settings.json (merge into existing blocks):"
cat <<EOF

  "env": {
    "OBSIDIAN_MEMORY_VAULT": "/absolute/path/to/your/vault/Projects",
    "OBSIDIAN_MEMORY_TEMPLATES": "$DEST/templates"
  },
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$DEST/hooks/obsidian-load.sh", "timeout": 10 } ] }
    ],
    "SessionEnd": [
      { "hooks": [ { "type": "command", "command": "$DEST/hooks/obsidian-save.sh", "timeout": 300, "async": true } ] }
    ]
  }
EOF

echo
echo "Note: the standalone hooks read templates from OBSIDIAN_MEMORY_TEMPLATES"
echo "(set above) because \${CLAUDE_PLUGIN_ROOT} is only defined under the plugin system."
