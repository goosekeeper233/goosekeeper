---
name: activate-workspace
description: Load a workspace configuration with its repos and knowledge
argument-hint: <workspace_name>
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
---

Load the specified workspace from `~/.claude/my/workspaces/<workspace_name>.json`.

## Steps

1. Read workspace config from `~/.claude/my/workspaces/<workspace_name>.json`
   - If not found, list available workspaces with `ls ~/.claude/my/workspaces/`

2. For each repo in `repos[]`:
   - Expand `~` to full home path
   - Read `<repo.path>/CLAUDE.md` if it exists
   - Summarize repo purpose and key patterns

3. Load any files listed in `sharedKnowledge[]`
   - Expand paths and read each file
   - Summarize key patterns

4. Note: Services are available in `~/.claude/my/services/registry.json`
   - Don't load all services automatically
   - Claude can look up services on-demand when needed

5. Update session state in `~/.claude/my/session.json`:
   - If file exists, update the `workspace` field
   - If file doesn't exist, create with just workspace:
     ```json
     {
       "workspace": "<name>",
       "started": "<ISO timestamp>"
     }
     ```
   This enables the stop hook to auto-log history when session ends.

6. Output summary:
   ```
   Workspace: <name>

   Repos:
   - <repo_name>: <brief summary from CLAUDE.md>

   Patterns Loaded:
   - <pattern_file>: <brief summary>

   Services available in registry: ~/.claude/my/services/registry.json

   Workspace active. Ready to work.
   ```

## Error Handling

- If workspace not found: List available workspaces
- If repo path doesn't exist: Warn but continue
