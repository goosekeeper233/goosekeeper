---
name: start-task
description: Start a new task or load an existing task's context
argument-hint: <task_id>
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Skill
---

Create a new task or load an existing task from `~/.claude/my/tasks/<task_id>/`.

## Steps

1. **Determine session file path** by running this Bash command:
   ```bash
   SESSIONS_DIR="$HOME/.claude/my/sessions"; mkdir -p "$SESSIONS_DIR"
   PID=$$; for i in 1 2 3 4 5; do
     P=$(ps -o ppid= -p $PID 2>/dev/null | tr -d ' ')
     [ -z "$P" ] || [ "$P" = "1" ] || [ "$P" = "0" ] && break
     COMM=$(ps -o comm= -p "$P" 2>/dev/null)
     echo "$COMM" | grep -qiE 'claude|node' && { echo "$SESSIONS_DIR/$P.json"; exit 0; }
     PID=$P
   done
   echo "$SESSIONS_DIR/${PPID:-default}.json"
   ```
   Use the output as `SESSION_FILE_PATH` for all subsequent session file operations.

2. Write session state to `SESSION_FILE_PATH` (the path from step 1):
   ```json
   {
     "task": "<task_id>",
     "workspace": null,
     "started": "<ISO timestamp>"
   }
   ```
   This must happen before any other step so that if the session is interrupted,
   the stop hook and PostToolUse hook can still function correctly.

3. Check if `~/.claude/my/tasks/<task_id>/` exists

4. If directory does NOT exist (new task):
   - Create the directory with `mkdir -p`
   - Create `prompt.md` with template:
     ```markdown
     # <task_id>: [Title]

     ## Workspace
     [workspace_name]

     ## Requirements
     -

     ## Acceptance Criteria
     - [ ]

     ## Constraints
     -

     ## Links
     - Jira:
     - Figma:
     ```
   - Tell user: "Created new task. Please fill in prompt.md with requirements."
   - Show the file path

5. If directory EXISTS (existing task):
   - Search history for this task:
     - Grep `~/.claude/my/history/*.jsonl` for entries containing this task_id
     - Show recent entries (last 5-10) to understand previous work
   - Read `prompt.md` for requirements
   - If `prompt.md` specifies a Workspace field:
     - Invoke `/goosekeeper:activate-workspace` for it
     - Update `SESSION_FILE_PATH` to set the `workspace` field
   - Read `progress.md` if exists:
     - Show completed items
     - Show in-progress items
     - Show handoff notes from previous session
   - Read `decisions.md` if exists:
     - Summarize key decisions already made

6. Create or update `progress.md`:
   - Set Status to `in_progress`
   - Add session start timestamp
   - Preserve existing content

## Output Format

For new task:
```
Created task: <task_id>
Location: ~/.claude/my/tasks/<task_id>/

Please edit prompt.md with your requirements, then run /goosekeeper:start-task <task_id> again.
```

For existing task:
```
Task: <task_id> - <title>
Workspace: <workspace_name> (activated)

Recent History:
<list recent history entries for this task>

Requirements:
<summary of requirements>

Progress:
- Completed: <count> items
- In Progress: <count> items
- Blocked: <count> items

Handoff Notes:
<notes from previous session if any>

Ready to continue.
```
