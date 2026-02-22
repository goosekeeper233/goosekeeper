#!/bin/bash

# Resolves the per-process session file path for the current Claude Code instance.
#
# Source this file in hooks to set SESSION_FILE and SESSIONS_DIR.
# Execute directly to print the session file path.
#
# Each Claude Code terminal gets its own session file, keyed by the Claude
# process PID. This prevents concurrent terminals from clobbering each other's
# session state.

SESSIONS_DIR="$HOME/.claude/my/sessions"
mkdir -p "$SESSIONS_DIR"

_resolve_claude_pid() {
  local pid=$$
  local depth=0

  while [[ $depth -lt 5 ]]; do
    local parent
    parent=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [[ -z "$parent" || "$parent" == "1" || "$parent" == "0" ]] && break

    local comm
    comm=$(ps -o comm= -p "$parent" 2>/dev/null)
    if echo "$comm" | grep -qiE 'claude|node'; then
      echo "$parent"
      return
    fi

    pid="$parent"
    depth=$((depth + 1))
  done

  # Fallback to PPID if we can't find claude/node in the tree
  echo "${PPID:-default}"
}

CLAUDE_PID=$(_resolve_claude_pid)
SESSION_FILE="$SESSIONS_DIR/$CLAUDE_PID.json"

# When executed directly (not sourced), print the path
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "$SESSION_FILE"
fi
