#!/bin/bash

# Goosekeeper SessionStart Hook
# Injects active task context into the session at startup
# Outputs JSON with additionalContext for Claude Code to consume

set -euo pipefail

# Paths
MY_DIR="$HOME/.claude/my"
SESSION_FILE="$MY_DIR/session.json"
TASKS_DIR="$MY_DIR/tasks"

# If no session state exists, nothing to inject
if [[ ! -f "$SESSION_FILE" ]]; then
  exit 0
fi

# Read session state
SESSION_DATA=$(cat "$SESSION_FILE")
TASK_ID=$(echo "$SESSION_DATA" | jq -r '.task // empty')
WORKSPACE=$(echo "$SESSION_DATA" | jq -r '.workspace // empty')
SESSION_START=$(echo "$SESSION_DATA" | jq -r '.started // empty')

# If no active task, nothing to inject
if [[ -z "$TASK_ID" ]]; then
  exit 0
fi

TASK_DIR="$TASKS_DIR/$TASK_ID"

# Build context using printf for proper newlines
CONTEXT="Active Task: $TASK_ID"

if [[ -n "$WORKSPACE" ]]; then
  CONTEXT=$(printf '%s\nWorkspace: %s' "$CONTEXT" "$WORKSPACE")
fi

if [[ -n "$SESSION_START" ]]; then
  CONTEXT=$(printf '%s\nSession started: %s' "$CONTEXT" "$SESSION_START")
fi

# Append prompt.md content if it exists
if [[ -f "$TASK_DIR/prompt.md" ]]; then
  PROMPT_CONTENT=$(cat "$TASK_DIR/prompt.md")
  CONTEXT=$(printf '%s\n\n--- Task Prompt ---\n%s' "$CONTEXT" "$PROMPT_CONTENT")
fi

# Append progress.md content if it exists
if [[ -f "$TASK_DIR/progress.md" ]]; then
  PROGRESS_CONTENT=$(cat "$TASK_DIR/progress.md")
  CONTEXT=$(printf '%s\n\n--- Progress ---\n%s' "$CONTEXT" "$PROGRESS_CONTENT")
fi

# Append decisions.md content if it exists
if [[ -f "$TASK_DIR/decisions.md" ]]; then
  DECISIONS_CONTENT=$(cat "$TASK_DIR/decisions.md")
  CONTEXT=$(printf '%s\n\n--- Decisions ---\n%s' "$CONTEXT" "$DECISIONS_CONTENT")
fi

# Check for handoff notes in progress.md (handles last section in file)
if [[ -f "$TASK_DIR/progress.md" ]]; then
  HANDOFF=$(awk '/^## Handoff/{found=1; next} /^## [^H]/{if(found) exit} found' "$TASK_DIR/progress.md" | head -20)
  if [[ -n "$HANDOFF" ]]; then
    CONTEXT=$(printf '%s\n\n--- Handoff Notes ---\n%s' "$CONTEXT" "$HANDOFF")
  fi
fi

# Output the additionalContext JSON for Claude Code to consume
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

exit 0
