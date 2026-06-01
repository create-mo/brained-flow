# brained-flow

A personal knowledge-driven workflow system for Claude — connecting your local brain/ wiki with claude.ai Projects, Claude Code CLI, and VS Code.

## What you get

| Skill | Where | What it does |
|-------|-------|-------------|
| `brain-sync` | Cowork | Use the brain/ ↔ claude.ai sync system |
| `wiki-setup` | Cowork | Install and configure the sync system from scratch |
| `brain-plan` | Cowork | Plan tasks grounded in wiki context |
| `brain-run` | Cowork | Execute plans step by step with subagents |
| `/brain-plan` | Claude Code / VS Code | Create detailed execution plans |
| `/brain-run` | Claude Code / VS Code | Execute plans via subagents |

## How it works

```
Edit brain/ locally (Obsidian or any editor)
    → wiki-watch auto-pushes to claude.ai Project (5s debounce)
    → Claude sees your project context in every conversation

Plan a task → brain-plan loads relevant wiki, creates plans/<date>_<slug>.md
    → brain-run executes steps via subagents, grounded in wiki + known-issues
    → Solutions and blockers written back to wiki
    → wiki-watch pushes updates to claude.ai
```

## Installation

### 1. Clone the repo

```powershell
git clone https://github.com/create-mo/brained-flow.git
cd brained-flow
```

### 2. Install skills (Cowork)

Run the install script:

```powershell
.\install.ps1
```

Or manually copy `skills/*` folders to your Cowork skills directory.

### 3. Install commands (Claude Code / VS Code)

Copy `commands/*.md` to your project's `.claude/commands/` folder:

```powershell
Copy-Item commands\*.md .\.claude\commands\
```

### 4. Set up brain/ sync

Follow `skills/wiki-setup/SKILL.md` — or ask Claude:
*"Help me set up the wiki sync system"*

## Requirements

- Python 3.x
- Windows (wiki-watch.ps1 uses PowerShell FileSystemWatcher)
- claude.ai account with Projects enabled
- Claude Cowork (for Cowork skills)
- Claude Code CLI (for slash commands)

## Security note

The sync system uses your claude.ai session key stored in `~/.claude/claude-ai-session.key`.
**Never commit this file.** Add to `.gitignore`:
```
~/.claude/claude-ai-session.key
```

## License

MIT © 2026 Mahmud Salakhetdinov
