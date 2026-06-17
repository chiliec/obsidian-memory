#!/usr/bin/env bash
# On SessionStart, inject the Obsidian SUMMARY.md (if any) as additional context.
# No-op when: (a) recursion guard set, (b) vault unconfigured/missing,
# (c) jq unavailable, (d) no matching project folder, (e) no SUMMARY.md.

set -u

# Skip when re-entered by the summarizer subprocess.
[ -n "${CLAUDE_OBSIDIAN_SYNCING:-}" ] && exit 0

# Vault root is user-configured. Unset → silent no-op (un-configured install).
OBSIDIAN_BASE="${OBSIDIAN_MEMORY_VAULT:-}"
[ -z "$OBSIDIAN_BASE" ] && exit 0
[ ! -d "$OBSIDIAN_BASE" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="$PWD"

PROJECT_NAME=$(basename "$CWD")
SUMMARY="$OBSIDIAN_BASE/$PROJECT_NAME/SUMMARY.md"

[ ! -f "$SUMMARY" ] && exit 0

CONTENT=$(cat "$SUMMARY")

jq -n \
  --arg ctx "Obsidian project summary from previous session (loaded from $SUMMARY):

$CONTENT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
