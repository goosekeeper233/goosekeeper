---
name: resume-task
description: Resume a task from where the last agent left off, with focus on handoff notes
argument-hint: <task_id>
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

Resume a task from `~/.claude/my/tasks/<task_id>/` with focus on handoff notes.

## Steps

1. Check if `~/.claude/my/tasks/<task_id>/` exists
   - If not: Error - "Task not found. Use /goosekeeper:start-task to create it."

2. Read `progress.md` and extract:
   - Current status
   - In-progress items (what was being worked on)
   - Handoff notes (critical context from last session)

3. Invoke `/goosekeeper:start-task <task_id>` to load full context

4. Highlight handoff notes prominently

5. Ask user: "Continue from handoff point, or review full progress first?"

## Output Format

```
Resuming Task: <task_id> - <title>

Last Session Handoff:
---
<handoff notes>
---

In Progress When Stopped:
- <item 1>
- <item 2>

Options:
1. Continue from handoff point
2. Review full progress first
3. Start fresh (ignore previous progress)

What would you like to do?
```

## Notes

- This command is for picking up work from a previous agent session
- Handoff notes are the primary focus - they contain context the previous agent wanted to pass along
- Always load workspace context via /goosekeeper:start-task
