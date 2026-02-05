#!/bin/bash

# Goosekeeper Stop Hook
# Logs semantic history entries from progress.md and git commits
# Non-blocking - saves state silently and allows exit

set -euo pipefail

# Paths
MY_DIR="$HOME/.claude/my"
SESSION_FILE="$MY_DIR/session.json"
HISTORY_DIR="$MY_DIR/history"
TASKS_DIR="$MY_DIR/tasks"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get current timestamp
TIMESTAMP=$(date +"%H:%M")
TODAY=$(date +"%Y-%m-%d")

# Ensure history directory exists
mkdir -p "$HISTORY_DIR"

# Check if session state exists
if [[ ! -f "$SESSION_FILE" ]]; then
  exit 0
fi

# Read session state
SESSION_DATA=$(cat "$SESSION_FILE")
TASK_ID=$(echo "$SESSION_DATA" | jq -r '.task // empty')
WORKSPACE=$(echo "$SESSION_DATA" | jq -r '.workspace // empty')

# ── Build "did" list from progress.md completed items ──────────────────
ACTIONS='["session ended"]'

if [[ -n "$TASK_ID" ]]; then
  PROGRESS_FILE="$TASKS_DIR/$TASK_ID/progress.md"

  if [[ -f "$PROGRESS_FILE" ]]; then
    # Extract completed items (lines starting with "- [x]")
    COMPLETED_ITEMS=$(grep '^- \[x\]' "$PROGRESS_FILE" 2>/dev/null | \
      sed 's/^- \[x\] //' | \
      tail -10)

    # Extract next steps (lines after "## Next" until next section or EOF)
    NEXT_ITEMS=$(awk '/^## Next/{found=1; next} /^## [^N]/{if(found) exit} found && /^[^$]/' "$PROGRESS_FILE" 2>/dev/null | \
      sed 's/^### //' | \
      grep -v '^$' | \
      head -3 | \
      tr '\n' '|' | \
      sed 's/|$//')

    if [[ -n "$COMPLETED_ITEMS" ]]; then
      ACTIONS=$(echo "$COMPLETED_ITEMS" | jq -R -s 'split("\n") | map(select(length > 0)) | .[0:10]')
    fi
  fi

  # ── Extract recent git commit messages from workspace repos ────────────
  if [[ -n "$WORKSPACE" ]]; then
    WS_FILE="$MY_DIR/workspaces/${WORKSPACE}.json"
    if [[ -f "$WS_FILE" ]]; then
      REPO_PATHS=$(jq -r '.repos[].path' "$WS_FILE" 2>/dev/null | sed "s|^~|$HOME|")
      GIT_COMMITS=""
      for REPO in $REPO_PATHS; do
        if [[ -d "$REPO/.git" ]]; then
          # Get commits from today by the current user
          REPO_COMMITS=$(cd "$REPO" && git log --since="$TODAY" --oneline 2>/dev/null | head -3)
          if [[ -n "$REPO_COMMITS" ]]; then
            REPO_NAME=$(basename "$REPO")
            GIT_COMMITS="${GIT_COMMITS}${REPO_NAME}: ${REPO_COMMITS}\n"
          fi
        fi
      done
    fi
  fi
fi

# ── Build history entry ────────────────────────────────────────────────
HISTORY_ENTRY=$(jq -cn \
  --arg t "$TIMESTAMP" \
  --arg task "$TASK_ID" \
  --arg ws "$WORKSPACE" \
  --argjson did "$ACTIONS" \
  --arg next "${NEXT_ITEMS:-}" \
  --arg commits "${GIT_COMMITS:-}" \
  '{t: $t} +
   (if $task != "" then {task: $task} else {} end) +
   (if $ws != "" then {ws: $ws} else {} end) +
   {did: $did} +
   (if $next != "" then {next: $next} else {} end) +
   (if $commits != "" then {commits: $commits} else {} end)')

# Append to today's history file
echo "$HISTORY_ENTRY" >> "$HISTORY_DIR/$TODAY.jsonl"

# Update task progress with session end timestamp
if [[ -n "$TASK_ID" ]]; then
  PROGRESS_FILE="$TASKS_DIR/$TASK_ID/progress.md"

  if [[ -f "$PROGRESS_FILE" ]]; then
    END_TIME=$(date +"%Y-%m-%d %H:%M")

    if ! grep -q "## Session Ended" "$PROGRESS_FILE"; then
      echo "" >> "$PROGRESS_FILE"
      echo "## Session Ended: $END_TIME" >> "$PROGRESS_FILE"
    else
      sed -i '' "s/## Session Ended:.*/## Session Ended: $END_TIME/" "$PROGRESS_FILE"
    fi
  fi
fi

# Keep session.json so SessionStart hook can inject context on next session.
# Only /start-task and /resume-task overwrite it.

exit 0
