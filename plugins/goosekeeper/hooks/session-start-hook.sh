#!/bin/bash

# Goosekeeper SessionStart Hook
# Injects active task context into the session at startup
# Outputs JSON with additionalContext for Claude Code to consume

set -o pipefail

# Paths
MY_DIR="$HOME/.claude/my"
TASKS_DIR="$MY_DIR/tasks"
LEGACY_SESSION="$MY_DIR/session.json"

# Resolve per-process session file
source "$(dirname "$0")/lib/resolve-session.sh"

# ── Clean up stale session files for dead processes ──────────────────────
for f in "$SESSIONS_DIR"/*.json; do
  [[ -f "$f" ]] || continue
  stale_pid=$(basename "$f" .json)
  # Skip non-numeric filenames (e.g., "default.json")
  [[ "$stale_pid" =~ ^[0-9]+$ ]] || continue
  # Skip our own session file
  [[ "$stale_pid" == "$CLAUDE_PID" ]] && continue
  # Remove if the process no longer exists
  if ! ps -p "$stale_pid" > /dev/null 2>&1; then
    rm -f "$f"
  fi
done

# ── Determine which session file to read ─────────────────────────────────
# Prefer per-process session file (if it somehow already exists).
# Fall back to legacy session.json (cross-session persistence).
SOURCE_FILE=""
if [[ -f "$SESSION_FILE" ]]; then
  SOURCE_FILE="$SESSION_FILE"
elif [[ -f "$LEGACY_SESSION" ]]; then
  SOURCE_FILE="$LEGACY_SESSION"
  # Migrate: copy legacy state to per-process file
  cp "$LEGACY_SESSION" "$SESSION_FILE"
fi

if [[ -z "$SOURCE_FILE" ]]; then
  exit 0
fi

# Read session state
SESSION_DATA=$(cat "$SOURCE_FILE")
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
