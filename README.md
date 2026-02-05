# Goosekeeper

Personal workspace, task, and knowledge management system for multi-repo workflows.

## Features

- **Workspaces**: Group multiple repos together with shared knowledge
- **Tasks**: Track progress, decisions, and handoffs across agent sessions
- **Services**: Central registry for external APIs (Swagger URLs, knowledge docs)
- **History**: Daily activity logs for cross-task tracking

## Installation

```bash
claude plugins install github:goosekeeper233/goosekeeper
```

Then initialize your data directory: `~/.claude/my/`

## Commands

| Command | Usage | Description |
|---------|-------|-------------|
| activate-workspace | `/goosekeeper:activate-workspace pipeline` | Load a workspace with its repos and patterns |
| start-task | `/goosekeeper:start-task DRO-12345` | Create or load a task |
| resume-task | `/goosekeeper:resume-task DRO-12345` | Resume with focus on handoff notes |

## Data Directory

All user data lives in `~/.claude/my/`:

```
~/.claude/my/
├── workspaces/          # Workspace definitions
├── services/            # Service registry
├── knowledge/           # Shared patterns and API docs
├── tasks/               # Per-task state
├── history/             # Daily activity logs
└── schemas/             # Format definitions
```

## Quick Start

1. Create a workspace:
   ```json
   // ~/.claude/my/workspaces/myproject.json
   {
     "name": "myproject",
     "description": "My Project - UI + API",
     "repos": [
       { "name": "ui", "path": "~/code/myproject-ui" },
       { "name": "api", "path": "~/code/myproject-api" }
     ],
     "sharedKnowledge": []
   }
   ```

2. Activate it:
   ```
   /goosekeeper:activate-workspace myproject
   ```

3. Start a task:
   ```
   /goosekeeper:start-task JIRA-123
   ```

## Documentation

See `~/.claude/my/README.md` for full system documentation.
