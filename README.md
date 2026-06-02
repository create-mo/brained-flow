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

```bash
git clone https://github.com/create-mo/brained-flow.git
cd brained-flow
```

### 2. Run the installer for your OS

**Windows:**
```powershell
.\install.ps1
```

**macOS:**
```bash
chmod +x install-macos.sh && ./install-macos.sh
# Requires: brew install fswatch
```

**Linux:**
```bash
chmod +x install-linux.sh && ./install-linux.sh
# Requires: sudo apt install inotify-tools
```

### 3. Set up brain/ sync

Follow `skills/wiki-setup/SKILL.md` — or ask Claude:
*"Help me set up the wiki sync system"*

### 4. Customize commands for your project

The slash commands `/brain-plan`, `/brain-run`, and `/wiki` are templates — they need to be adapted to your stack before use.

Open each file and replace the `[НАСТРОИТЬ]` / `[CUSTOMIZE]` blocks:

| File | What to fill in |
|------|----------------|
| `commands/brain-plan.md` | Your tech stack, critical invariants, topic → wiki file mappings |
| `commands/brain-run.md` | Your stack, critical invariants, verification command (`tsc`, `pytest`, `cargo check`, etc.) |
| `commands/wiki.md` | Paths to your source dirs, your wiki file names, topic → file mappings |

**Example — topic mappings for a Django + React project:**
```
auth / login / session      → auth.md
models / migration / orm    → data.md
api / views / serializer    → api.md
components / hooks / styles → frontend.md
celery / worker / task      → async.md
```

Copy `commands/` into your project's `.claude/commands/` folder (the installer does this automatically).

## Requirements

- Python 3.x
- claude.ai account with Projects enabled
- Claude Cowork (for Cowork skills)
- Claude Code CLI (for slash commands)

**OS-specific:**
| OS | File watcher |
|----|-------------|
| Windows | built-in (PowerShell FileSystemWatcher) |
| macOS | `brew install fswatch` |
| Linux | `sudo apt install inotify-tools` |

## Security note

The sync system uses your claude.ai session key stored in `~/.claude/claude-ai-session.key`.
**Never commit this file.** Add to `.gitignore`:
```
~/.claude/claude-ai-session.key
```

## License

MIT © 2026 Mahmud Salakhetdinov
