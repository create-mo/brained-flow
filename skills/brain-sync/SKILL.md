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

Two-way sync between a local `brain/` Markdown wiki and claude.ai Projects.

## How it works

```
Edit brain/ → wiki-watch auto-pushes to claude.ai (5s delay)
claude.ai / mobile edits → wiki-pull.py pulls changes back to brain/
```

## Important: scripts live in brain/, not in this repo

`wiki-push.py`, `wiki-pull.py`, and `wiki-watch.ps1` are **personal scripts** that must exist inside the user's `brain/` folder. They are not included in brained-flow because they contain the user's session key and Project ID.

**If the scripts don't exist yet**, offer to create them. Ask:
1. Path to their `brain/` folder (e.g. `C:\Users\name\brain`)
2. Their claude.ai Project name (must match exactly — see warning below)
3. Their claude.ai Project ID (found in the URL: `claude.ai/project/<project-id>`)

Then generate the three scripts (see templates below) and save them to `brain/`.

## Script templates

### wiki-push.py
```python
import os, sys, json, pathlib, urllib.request, urllib.error

SESSION_KEY_FILE = os.path.expanduser("~/.claude/claude-ai-session.key")
PROJECT_NAME = "<your-project-name>"   # must match claude.ai and Cowork exactly
BRAIN_DIR = pathlib.Path(__file__).parent

def get_session_key():
    if not os.path.exists(SESSION_KEY_FILE):
        print(f"Session key not found at {SESSION_KEY_FILE}")
        print("Get it from claude.ai: F12 → Application → Cookies → sessionKey")
        sys.exit(1)
    return open(SESSION_KEY_FILE).read().strip()

def check_session_key(session_key):
    """Validate session key before doing anything — fail loud, not silent."""
    url = "https://claude.ai/api/auth/session"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            print("ERROR: Session key is expired or invalid.")
            print("Fix:   F12 → Application → Cookies → claude.ai → sessionKey")
            print(f"Save:  echo 'YOUR_KEY' > {SESSION_KEY_FILE}")
            sys.exit(1)
        pass  # 404 = endpoint removed from API, but key is valid — continue

def get_project_id(session_key):
    url = "https://claude.ai/api/organizations"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    data = json.loads(urllib.request.urlopen(req).read())
    org_id = data[0]["uuid"]
    url = f"https://claude.ai/api/organizations/{org_id}/projects"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    projects = json.loads(urllib.request.urlopen(req).read())
    for p in projects:
        if p["name"] == PROJECT_NAME:
            return org_id, p["uuid"]
    print(f"Project '{PROJECT_NAME}' not found. Check the name matches claude.ai exactly.")
    sys.exit(1)

def push_files(session_key, org_id, project_id):
    md_files = list(BRAIN_DIR.rglob("*.md"))
    print(f"Pushing {len(md_files)} files to '{PROJECT_NAME}'...")
    for f in md_files:
        content = f.read_text(encoding="utf-8")
        name = str(f.relative_to(BRAIN_DIR))
        payload = json.dumps({"file_name": name, "content": content}).encode()
        url = f"https://claude.ai/api/organizations/{org_id}/projects/{project_id}/docs"
        req = urllib.request.Request(url, data=payload, method="POST",
            headers={"Cookie": f"sessionKey={session_key}", "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
        try:
            urllib.request.urlopen(req)
            print(f"  OK  {name}")
        except urllib.error.HTTPError as e:
            if e.code in (401, 403):
                print("ERROR: Session key expired mid-push. Stopping.")
                print(f"Fix:   refresh key, then re-run wiki-push.py")
                sys.exit(1)
            print(f"  ERR {name}: {e}")

key = get_session_key()
check_session_key(key)
org_id, proj_id = get_project_id(key)
push_files(key, org_id, proj_id)
print("Done.")
```

### wiki-pull.py
```python
import os, sys, json, pathlib, urllib.request

SESSION_KEY_FILE = os.path.expanduser("~/.claude/claude-ai-session.key")
PROJECT_NAME = "<your-project-name>"
BRAIN_DIR = pathlib.Path(__file__).parent

def get_session_key():
    if not os.path.exists(SESSION_KEY_FILE):
        print(f"Session key not found at {SESSION_KEY_FILE}")
        sys.exit(1)
    return open(SESSION_KEY_FILE).read().strip()

def check_session_key(session_key):
    url = "https://claude.ai/api/auth/session"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            print("ERROR: Session key is expired or invalid.")
            print("Fix:   F12 → Application → Cookies → claude.ai → sessionKey")
            print(f"Save:  echo 'YOUR_KEY' > {SESSION_KEY_FILE}")
            sys.exit(1)
        pass  # 404 = endpoint removed from API, but key is valid — continue

def get_project_id(session_key):
    url = "https://claude.ai/api/organizations"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    data = json.loads(urllib.request.urlopen(req).read())
    org_id = data[0]["uuid"]
    url = f"https://claude.ai/api/organizations/{org_id}/projects"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    projects = json.loads(urllib.request.urlopen(req).read())
    for p in projects:
        if p["name"] == PROJECT_NAME:
            return org_id, p["uuid"]
    print(f"Project '{PROJECT_NAME}' not found.")
    sys.exit(1)

def pull_files(session_key, org_id, project_id):
    url = f"https://claude.ai/api/organizations/{org_id}/projects/{project_id}/docs"
    req = urllib.request.Request(url, headers={"Cookie": f"sessionKey={session_key}", "User-Agent": "Mozilla/5.0"})
    docs = json.loads(urllib.request.urlopen(req).read())
    print(f"Pulling {len(docs)} files from '{PROJECT_NAME}'...")
    for doc in docs:
        dest = BRAIN_DIR / doc["file_name"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(doc["content"], encoding="utf-8")
        print(f"  OK  {doc['file_name']}")

key = get_session_key()
check_session_key(key)
org_id, proj_id = get_project_id(key)
pull_files(key, org_id, proj_id)
print("Done.")
```

### wiki-watch.ps1 (Windows only)
```powershell
$BRAIN_DIR = $PSScriptRoot
$DEBOUNCE = 5  # seconds

Write-Host "Watching $BRAIN_DIR for changes..."
$watcher = New-Object System.IO.FileSystemWatcher $BRAIN_DIR -Property @{
    IncludeSubdirectories = $true; EnableRaisingEvents = $true
    Filter = "*.md"
}
$timer = $null
$action = {
    if ($timer) { $timer.Stop(); $timer.Dispose() }
    $script:timer = New-Object System.Timers.Timer
    $script:timer.Interval = $DEBOUNCE * 1000
    $script:timer.AutoReset = $false
    Register-ObjectEvent $script:timer Elapsed -Action {
        Write-Host "$(Get-Date -Format HH:mm:ss) Changes detected — pushing..."
        python "$BRAIN_DIR\wiki-push.py"
    } | Out-Null
    $script:timer.Start()
}
Register-ObjectEvent $watcher Changed -Action $action | Out-Null
Register-ObjectEvent $watcher Created -Action $action | Out-Null
Register-ObjectEvent $watcher Deleted -Action $action | Out-Null
while ($true) { Start-Sleep 1 }
```

### wiki-watch.sh (macOS and Linux)

The repo includes `wiki-watch.sh` — a cross-platform bash watcher. Copy it to `brain/`:

```bash
cp /path/to/brained-flow/wiki-watch.sh ~/brain/wiki-watch.sh
chmod +x ~/brain/wiki-watch.sh
```

Requirements:
- macOS: `brew install fswatch`
- Linux: `sudo apt install inotify-tools` (or dnf/pacman)

Run manually:
```bash
cd ~/brain
./wiki-watch.sh
```

## Session key setup

The scripts authenticate using the claude.ai session cookie:

1. Open claude.ai in browser
2. Press F12 → Application → Cookies → claude.ai → find `sessionKey`
3. Save it: `"YOUR_KEY" | Out-File "$env:USERPROFILE\.claude\claude-ai-session.key" -Encoding ascii -NoNewline`

If sync stops working, the session key has likely expired — repeat the steps above.

## Can't get a session key? Use the v2 Browser Bridge

On Chrome 127+ the `sessionKey` cookie is sealed by App-Bound Encryption (cookie
v20) and can no longer be read or decrypted programmatically. If you can't copy
the cookie out, or you just don't want to manage an expiring key, use the
**browser bridge** in `v2-browser-bridge/` instead.

Idea: don't extract the key — run the sync *inside* the logged-in claude.ai tab
via the Claude in Chrome extension. The browser attaches the cookie to every
same-origin `fetch` itself, so no key is stored anywhere and nothing expires.

| File | What it is |
|------|-----------|
| `v2-browser-bridge/bridge.js` | In-page `pull` / `push` / `pushMany` — paste into `javascript_tool` on a claude.ai tab. Org ID is resolved at runtime; nothing hardcoded. |
| `v2-browser-bridge/sync.py` | Two-way merge engine (hashes + manifest). Runs locally; remote I/O goes through the bridge. Projects come from `$BRAIN_DIR/.sync-projects.json`. |
| `v2-browser-bridge/RUNBOOK.md` | Step-by-step pull / push / merge flow and limitations. |

When to reach for it:

- `wiki-push.py` / `wiki-pull.py` fail to authenticate and refreshing the key
  doesn't help (App-Bound Encryption) → switch to the bridge.
- You want two-way merge with conflict handling rather than blind push/pull →
  use `sync.py` (see RUNBOOK).

Trade-off: the bridge needs an open Chrome with the extension connected — there's
no silent background cron. For unattended sync, keep the sessionKey scripts.

## Auto-start on login

**Offer to set this up** when helping a user — they often don't know it's possible.

### Windows — Startup folder (.vbs launcher)

```vbscript
' Save as: %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\wiki-watch.vbs
CreateObject("WScript.Shell").Run "powershell -WindowStyle Hidden -File ""C:\path\to\brain\wiki-watch.ps1""", 0, False
```

Replace `C:\path\to\brain\` with the actual path to `brain/`.

### macOS — launchd plist

```xml
<!-- Save as: ~/Library/LaunchAgents/com.brain.wiki-watch.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>             <string>com.brain.wiki-watch</string>
  <key>ProgramArguments</key>  <array><string>/bin/bash</string><string>/path/to/brain/wiki-watch.sh</string></array>
  <key>RunAtLoad</key>         <true/>
  <key>KeepAlive</key>         <true/>
  <key>StandardOutPath</key>   <string>/tmp/wiki-watch.log</string>
  <key>StandardErrorPath</key> <string>/tmp/wiki-watch.log</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.brain.wiki-watch.plist
```

### Linux — systemd user service

```ini
# Save as: ~/.config/systemd/user/wiki-watch.service
[Unit]
Description=brain/ wiki watcher
After=network.target

[Service]
ExecStart=/bin/bash /path/to/brain/wiki-watch.sh
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user enable wiki-watch
systemctl --user start wiki-watch
```

## Synced Projects

| Project name | Project ID |
|---|---|
| `<your-project-name>` | `<your-project-id>` |

Find your Project ID in the claude.ai URL when viewing the project: `claude.ai/project/<project-id>`.

> **⚠️ Critical — naming must match exactly across all surfaces:**
> The project name must be identical in:
> - `claude.ai` — the Project name as shown in the sidebar
> - `Claude Cowork` — the folder/project name in Cowork
> - `wiki-push.py` / `wiki-pull.py` — the `PROJECT_NAME` variable in the scripts
>
> A mismatch means files push to the wrong project or sync silently fails.
> When helping the user set up, always verify all three match before proceeding.

## Common tasks

**Push changes manually:**
```powershell
cd C:\path\to\brain
python wiki-push.py
```

**Pull latest from claude.ai:**
```powershell
cd C:\path\to\brain
python wiki-pull.py
```

**Start file watcher manually (if not running):**
```powershell
cd C:\path\to\brain
.\wiki-watch.ps1
```

**Check if watcher is running:**
```powershell
Get-Process powershell | Where-Object { $_.MainWindowTitle -like "*wiki-watch*" }
```

## When helping the user

- **Scripts missing entirely** → offer to create them using the templates above; ask for brain/ path, Project name, Project ID
- **Changes not appearing in claude.ai** → check if wiki-watch is running; offer to set up auto-start
- **Mobile shows stale content** → run `wiki-pull.py`; explain it's manual and offer to discuss automation
- **Authentication fails** → session key expired; guide through F12 → Cookies → refresh
- **After any task in Cowork** → remind user they can pull results back to brain/ with `wiki-pull.py`
- The sync is `.md` files only — other file types are not synced
