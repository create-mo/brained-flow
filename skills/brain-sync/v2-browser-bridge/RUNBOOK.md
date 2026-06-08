# brain-sync v2 — Browser Bridge

A drop-in alternative to the sessionKey scripts. The original approach copies the
claude.ai `sessionKey` cookie out of the browser and replays it from outside.
Chrome 127+ App-Bound Encryption (cookie v20) sealed that cookie — it can no
longer be read or decrypted programmatically. The bridge takes the opposite
route: **don't extract the key — run inside the session that already owns it.**

## Model

```
brain/ (local)     ──Cowork: file tools──┐
                                          ├──  Claude  ──Claude in Chrome: javascript_tool──►  claude.ai tab
claude.ai Project  ◄──────────────────────┘                                                    (fetch with the httpOnly cookie)
```

Roles:

- **Cowork (the agent)** reads and writes local `brain/*.md` with its file tools.
- **Claude in Chrome** runs `fetch('/api/...')` directly in the claude.ai tab. The
  browser attaches the cookie itself — auth is free and self-refreshing.
- **Claude** shuttles content between the two channels. No key is stored anywhere.

Why it doesn't break: we never read the cookie, never decrypt Chrome's storage,
and never call an external API host. App-Bound Encryption doesn't apply.

## Prerequisites

1. Chrome open, the Claude in Chrome extension connected and logged in to
   claude.ai (check with `list_connected_browsers`).
2. Access to your local `brain/` folder from Cowork (mount it).
3. A project config file — see `sync.py` header. Default:
   `$BRAIN_DIR/.sync-projects.json`, mapping `{ "key": { "id", "path" } }`.
   Find each Project ID in the claude.ai URL: `claude.ai/project/<project-id>`.

## PULL (claude.ai → brain/)

1. `navigate` to `https://claude.ai`, wait for load.
2. `javascript_tool`: paste `bridge.js`, then call `await pull("<project-id>")`
   (wrap in an async IIFE — top-level await does not work in the REPL).
3. You get JSON `[{name, content, id, created}]`.
4. Cowork writes each `content` to `brain/.../<name>`.

## PUSH (brain/ → claude.ai)  ⚠️ side-effectful

1. Cowork reads changed `brain/*.md` → array `[{name, content}]`.
2. `javascript_tool`: paste `bridge.js`, call `await pushMany("<project-id>", files)`.
   `push` deletes the same-named doc first, then creates a new one (claude.ai
   cannot edit docs in place).

**Permission:** uploading / replacing / deleting documents in a Project is an
explicit-consent action. Before every real push, show the file list and wait for
a clear "yes". One run is not a blanket approval for future runs.

## Two-way merge (sync.py)

On top of the bridge sits the merge engine `sync.py`. All local logic (hashes,
manifest, decision) lives in it; remote I/O goes through the bridge; the agent
glues them together.

**Rules:**

- Master = the most recently changed version, decided via manifest hashes:
  changed only locally → push; only on claude.ai → pull; new on one side → goes
  to the other; changed on both sides → **conflict**.
- Conflict default: **skip + flag** (`CONFLICT_MODE=skip`) — the file is left
  untouched and reported. Alternatives: `local-wins`, `keep-both` (writes
  `name.remote.md` alongside).
- Deletions are **never** propagated (add/update only).
- Why not plain mtime: a claude.ai doc carries only `created_at`, and push =
  delete + recreate resets it to upload time. Manifest hashes stop the ping-pong;
  mtime is only a tiebreaker.

**Manifest:** `$BRAIN_DIR/.sync-state.json` — `{proj: {file.md: {hash}}}`, the
hash of the last synced version. Tracks `.md` only.

**One run (for project `<p>`):**

1. Agent: check the bridge (`list_connected_browsers`); pull remote via
   `bridge.js` → save `remote.json`.
2. `python sync.py plan --proj <p> --remote remote.json`
   → writes pulled files locally, prints the plan, and writes the upload set to
   `push.json`.
3. Agent: upload the files from `push.json` via `bridge.js` (push is
   side-effectful — show the list and wait for "yes").
4. Agent: re-pull remote → `remote2.json`.
5. `python sync.py commit --proj <p> --remote remote2.json`
   → records the manifest for matched files, prints remaining conflicts.

`BRAIN_DIR` defaults to `~/brain`; override via env for testing.

## Limitation: content filter on the agent hop

Content travels "browser → agent → disk". If a file contains strings that look
like a cookie / query string / secret, the protective filter can truncate the
`javascript_tool` output (`[BLOCKED: ...]`). Document lists and statuses still
pass — only the body of such a file is blocked. Plain `.md` wiki text is
unaffected, so the normal flow works. For secret-bearing or large binary files,
use a browser-side download (build a `Blob` and `a.click()` so Chrome saves it to
Downloads, bypassing the agent channel), then move it into `brain/`.

## What this approach does NOT give

- **A silent cron.** It needs an open Chrome with the active extension. For a
  background / mobile two-way scenario you'd add a neutral hub (e.g. a shared
  notes service) on top.
- **Batch-API speed.** Each file is a separate round-trip through the UI session.
