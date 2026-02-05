# Goosekeeper Workspace System

The user has a custom workspace, service, and task management system.

**System Index:** `~/.claude/my/README.md` (full documentation and file manifest)

## Locations

All custom data lives in `~/.claude/my/`:

| Path | Purpose |
|------|---------|
| `workspaces/*.json` | Workspace definitions (repos + patterns) |
| `services/registry.json` | Central service registry (looked up on-demand) |
| `knowledge/patterns/` | Cross-repo patterns and conventions |
| `knowledge/services/` | External API knowledge (for services without local code) |
| `tasks/<id>/` | Per-task state (prompt, progress, decisions) |
| `history/YYYY-MM-DD.jsonl` | Daily activity log (cross-task, cross-repo) |
| `schemas/*.json` | Format definitions for all file types |

## Available Commands

| Command | When to Use |
|---------|-------------|
| `/goosekeeper:activate-workspace <name>` | Start working on a project group |
| `/goosekeeper:start-task <id>` | Begin or load a specific task |
| `/goosekeeper:resume-task <id>` | Continue from previous agent handoff |

## Multi-Agent Coordination

When working on tasks:
- Always read `progress.md` before starting work
- Update `progress.md` when completing items or stopping
- Add key decisions to `decisions.md`
- Write handoff notes if stopping mid-task

## Service Knowledge

For external services (BE APIs without local repos):
- Check `services/registry.json` for swagger URLs
- Read corresponding knowledge file for context
- Note: User is FE dev, may only have swagger access to BE services

## Session State

When working on tasks or workspaces, session state is tracked in `~/.claude/my/session.json`:
```json
{
  "task": "TASK-ID",
  "workspace": "workspace-name",
  "started": "2026-02-05T10:30:00Z"
}
```

This file is:
- Created/updated by `/start-task` and `/activate-workspace` commands
- Read by the stop hook for automatic history logging
- Cleaned up when session ends

## Incremental Updates (IMPORTANT)

**Do NOT rely on the Stop hook for saving state** — the user often closes the terminal
tab, which kills the process without running hooks.

Instead, update history, progress, and knowledge **during the session** at natural
checkpoints. See `rules/incremental-updates.md` for detailed guidelines.

Quick summary:
- **Progress**: Update after completing task items or finding blockers
- **History**: Log after milestones (feature working, approach changed, key decision)
- **Knowledge**: Update when discovering reusable patterns or disproving existing ones

## History Format

**File:** `~/.claude/my/history/YYYY-MM-DD.jsonl`

**Format:** One JSON object per line:
```json
{"t":"HH:MM","task":"ID","ws":"workspace","did":["action1","action2"],"learned":"insight","next":"next step"}
```

Keep entries compact. `task`, `ws`, `learned`, `next` are optional.

## Stop Hook (Backup)

The stop hook reads from `progress.md` to generate a history entry on clean exit.
Since the agent updates incrementally, this serves as a safety net.
