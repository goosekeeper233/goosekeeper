# Incremental Updates (MANDATORY)

You MUST update progress, history, and knowledge at the END of EVERY response
that involves meaningful work. Do not batch to session end — the terminal may
close abruptly and the Stop hook is only a backup.

## What to Update at Each Response End

### 1. Progress (`~/.claude/my/tasks/<id>/progress.md`) — ALWAYS
- Add `- [x]` for any completed items
- Update "Next Steps" if they changed
- Update "Handoff" section with current context
- Files Modified is tracked automatically by PostToolUse hook

**Skip only when:** Asking clarifying questions with zero code/file changes.

### 2. History (`~/.claude/my/history/YYYY-MM-DD.jsonl`) — ALWAYS
Append a JSONL entry summarizing what this response accomplished:
```json
{"t":"HH:MM","task":"ID","ws":"workspace","did":[...],"learned":"...","next":"..."}
```
- `did`: array of concrete actions (1-4 items)
- `learned`: reusable insight if any (omit if nothing new)
- `next`: what comes next (1 line)

**Skip only when:** Response was purely conversational (no work done).

### 3. Knowledge (`~/.claude/my/knowledge/patterns/*.md`) — CHECK EACH TIME
At the end of each response, ask yourself: "Did I discover a reusable pattern
that applies beyond this specific task?" If yes, update or create a knowledge file.

Examples of knowledge-worthy patterns:
- TDS component behavior quirks (e.g., AppLayout min-block-size: 100vh)
- Auth/cookie setup steps for local dev
- BFF patterns (e.g., appName-based routing)
- React Router v7 constraints
- Playwright browser_run_code patterns for cross-domain cookie transfer

**Skip when:** The insight is purely task-specific (belongs in progress.md).

## Execution Order

At the end of each response:
1. Write progress.md updates (completed items, next steps, handoff)
2. Append history entry
3. Check if knowledge update is needed (usually not — most responses don't
   produce cross-task insights)

## The Stop Hook is a Backup

The Stop hook reads progress.md to generate a final history entry. Since the
agent updates incrementally, the Stop hook entry is redundant — but it catches
cases where the agent forgets or the terminal closes mid-response.
