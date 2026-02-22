#!/bin/bash

# Goosekeeper PreCompact Hook
# Saves history entry before compact to preserve context
# Non-blocking - logs and allows compact to proceed

set -o pipefail

# Paths
MY_DIR="$HOME/.claude/my"
HISTORY_DIR="$MY_DIR/history"
TASKS_DIR="$MY_DIR/tasks"

# Get current timestamp
TIMESTAMP=$(date +"%H:%M")
TODAY=$(date +"%Y-%m-%d")

# Ensure history directory exists
mkdir -p "$HISTORY_DIR"

# Resolve per-process session file
source "$(dirname "$0")/lib/resolve-session.sh"

# Check if session state exists
if [[ ! -f "$SESSION_FILE" ]]; then
  # No active session tracked - nothing to save
  exit 0
fi

# Read session state
SESSION_DATA=$(cat "$SESSION_FILE")
TASK_ID=$(echo "$SESSION_DATA" | jq -r '.task // empty')
WORKSPACE=$(echo "$SESSION_DATA" | jq -r '.workspace // empty')

# Build history entry for pre-compact
HISTORY_ENTRY=$(jq -cn \
  --arg t "$TIMESTAMP" \
  --arg task "$TASK_ID" \
  --arg ws "$WORKSPACE" \
  '{t: $t} +
   (if $task != "" then {task: $task} else {} end) +
   (if $ws != "" then {ws: $ws} else {} end) +
   {did: ["context compacted - continuing session"]}')

# Append to today's history file
echo "$HISTORY_ENTRY" >> "$HISTORY_DIR/$TODAY.jsonl"

# Update task progress if there's an active task
if [[ -n "$TASK_ID" ]]; then
  PROGRESS_FILE="$TASKS_DIR/$TASK_ID/progress.md"

  if [[ -f "$PROGRESS_FILE" ]]; then
    COMPACT_TIME=$(date +"%Y-%m-%d %H:%M")

    # Check if "## Last Compact" section exists, if not add it
    if ! grep -q "## Last Compact" "$PROGRESS_FILE"; then
      echo "" >> "$PROGRESS_FILE"
      echo "## Last Compact: $COMPACT_TIME" >> "$PROGRESS_FILE"
    else
      # Update existing last compact timestamp
      sed -i '' "s/## Last Compact:.*/## Last Compact: $COMPACT_TIME/" "$PROGRESS_FILE"
    fi
  fi
fi

# Allow compact to proceed (don't block)
exit 0
