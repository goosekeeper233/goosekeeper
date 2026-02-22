#!/bin/bash

# Goosekeeper UserPromptSubmit Hook
# Checks if the agent updated history since the last prompt.
# If not, outputs a reminder. This acts as enforcement for the
# incremental-updates rule.

set -o pipefail

MY_DIR="$HOME/.claude/my"
HISTORY_DIR="$MY_DIR/history"
MARKER_FILE="$MY_DIR/.last-update-check"
TODAY=$(date +"%Y-%m-%d")
HISTORY_FILE="$HISTORY_DIR/$TODAY.jsonl"

# Resolve per-process session file
source "$(dirname "$0")/lib/resolve-session.sh"

# No session = no check needed
if [[ ! -f "$SESSION_FILE" ]]; then
  exit 0
fi

TASK_ID=$(jq -r '.task // empty' "$SESSION_FILE")

# No active task = no check needed
if [[ -z "$TASK_ID" ]]; then
  exit 0
fi

# Get the last modification time of today's history file
if [[ -f "$HISTORY_FILE" ]]; then
  HISTORY_MTIME=$(stat -f %m "$HISTORY_FILE" 2>/dev/null || stat -c %Y "$HISTORY_FILE" 2>/dev/null || echo "0")
else
  HISTORY_MTIME="0"
fi

# Get the marker time (last time we checked)
if [[ -f "$MARKER_FILE" ]]; then
  MARKER_MTIME=$(cat "$MARKER_FILE")
else
  MARKER_MTIME="0"
fi

# Update the marker to current time
date +%s > "$MARKER_FILE"

# If this is the first check (marker was 0), skip — don't nag on session start
if [[ "$MARKER_MTIME" == "0" ]]; then
  exit 0
fi

# If history was updated since last check, agent is doing its job
if [[ "$HISTORY_MTIME" -gt "$MARKER_MTIME" ]]; then
  exit 0
fi

# History was NOT updated since last check — remind the agent
echo "Reminder: You did not update ~/.claude/my/history/$TODAY.jsonl or progress.md after your last response. Per the incremental-updates rule, you MUST update progress and history at the end of each response that involves meaningful work. Please do so before proceeding with the user's new request."
