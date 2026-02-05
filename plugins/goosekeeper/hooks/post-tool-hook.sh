#!/bin/bash

# Goosekeeper PostToolUse Hook
# Tracks file modifications by appending to task progress
# Matcher: Write|Edit — fires after file writes/edits
# Lightweight — append-only, no blocking

set -euo pipefail

# Paths
MY_DIR="$HOME/.claude/my"
SESSION_FILE="$MY_DIR/session.json"
TASKS_DIR="$MY_DIR/tasks"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# If no session state, nothing to track
if [[ ! -f "$SESSION_FILE" ]]; then
  exit 0
fi

# Read session state
TASK_ID=$(jq -r '.task // empty' "$SESSION_FILE")

# If no active task, nothing to track
if [[ -z "$TASK_ID" ]]; then
  exit 0
fi

PROGRESS_FILE="$TASKS_DIR/$TASK_ID/progress.md"

# Ensure task directory exists
mkdir -p "$TASKS_DIR/$TASK_ID"

# Extract the file path from hook input
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // "unknown"')

# Ensure progress file exists with header
if [[ ! -f "$PROGRESS_FILE" ]]; then
  cat > "$PROGRESS_FILE" << 'EOF'
# Progress

## Status

in_progress

## Files Modified
EOF
fi

# Add Files Modified section if it doesn't exist
if ! grep -q "## Files Modified" "$PROGRESS_FILE"; then
  echo "" >> "$PROGRESS_FILE"
  echo "## Files Modified" >> "$PROGRESS_FILE"
fi

# Skip if this file was already logged (deduplication)
if grep -qF "\`$FILE_PATH\`" "$PROGRESS_FILE" 2>/dev/null; then
  exit 0
fi

# Append the modification entry
echo "- \`$FILE_PATH\` ($TOOL_NAME)" >> "$PROGRESS_FILE"

exit 0
