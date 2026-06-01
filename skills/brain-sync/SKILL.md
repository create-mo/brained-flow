---
name: brain-sync
description: >
  Skill for working with the brain/ ↔ claude.ai Projects two-way sync system.
  Use this skill whenever the user mentions syncing files to claude.ai, pushing
  markdown to a Project, pulling from claude.ai, wiki-push, wiki-pull,
  wiki-watch, or asks about their brain/ knowledge base sync setup. Also use
  when the user wants to know what's in their claude.ai Project knowledge base,
  or wants to update it from local files.
---

# brain-sync

The user has a two-way sync system between their local `brain/` folder and claude.ai Projects.

## How it works

```
Edit brain/ → wiki-watch auto-pushes to claude.ai (5s delay)
Work on mobile → wiki-pull pulls changes back to brain/ on PC login
```

## Components

| Script | What it does |
|--------|-------------|
| `wiki-push.py` | Uploads `.md` files from `brain/` to claude.ai Project |
| `wiki-pull.py` | Downloads files from claude.ai Project back to `brain/` |
| `wiki-watch.ps1` | Watches for changes, auto-pushes after 5 seconds |
| `Startup/*.vbs` | Auto-starts wiki-watch on Windows login |

## Session key setup

The scripts authenticate using the claude.ai session cookie:

1. Open claude.ai in browser
2. Press F12 → Application → Cookies → claude.ai → find `sessionKey`
3. Save it to: `~/.claude/claude-ai-session.key`

If sync stops working, the session key has likely expired — repeat the steps above.

## Synced Projects

| Project name | Project ID |
|---|---|
| VPSS | `019e7061-5272-747f-a294-3650d76e0f01` |
| new claude abilities | `019e7085-ff9a-70bc-8f8e-2f3000d543d2` |

## Common tasks

**Push changes manually:**
```powershell
python wiki-push.py
```

**Pull latest from claude.ai:**
```powershell
python wiki-pull.py
```

**Start file watcher (if not running):**
```powershell
.\wiki-watch.ps1
```

**Check if watcher is running:**
```powershell
Get-Process | Where-Object { $_.MainWindowTitle -like "*wiki-watch*" }
```

## When helping the user

- If they edit files in `brain/` and ask why claude.ai isn't updated — check if wiki-watch is running
- If their mobile shows stale content — suggest running `wiki-pull.py` on PC
- If authentication fails — session key expired, need to refresh from browser cookies
- The sync is `.md` files only — other file types are not synced
