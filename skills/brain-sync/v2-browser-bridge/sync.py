#!/usr/bin/env python3
"""
brain-sync v2 — two-way merge engine (runs in the Cowork sandbox).

Role split:
  - This script does ALL the local logic: reading brain/, hashing, the manifest,
    deciding push/pull/conflict, and writing pulled files to disk.
  - Remote I/O (reading/writing docs on claude.ai) is done by the agent through
    the browser bridge (bridge.js). This script never touches the network — that
    is deliberate: the sessionKey approach is blocked by Chrome App-Bound
    Encryption, and claude.ai is only reachable from inside a logged-in tab.

Flow (orchestrated by the agent, see RUNBOOK.md):
  1. agent: pull remote via the bridge      -> remote.json
  2. python sync.py plan   --proj <p> --remote remote.json
        -> writes pulled files to disk (pull)
        -> prints the plan + a push payload (files to upload) to push.json
        -> conflicts are flagged, never silently overwritten
  3. agent: upload the files listed in push.json via the bridge
  4. agent: re-pull remote                   -> remote2.json
  5. python sync.py commit --proj <p> --remote remote2.json
        -> records the manifest for matched files, prints remaining conflicts

Rules:
  - master = the most recently changed version, decided via manifest hashes:
      changed only locally          -> push
      changed only on claude.ai     -> pull
      new file on one side          -> goes to the other side
      changed on BOTH sides         -> CONFLICT (default: skip + flag)
  - deletions are NEVER propagated (add/update only)

Project config (no IDs are hardcoded — keep your own out of the repo):
  Provide a JSON file mapping project keys to {id, path}. Default location:
  $BRAIN_DIR/.sync-projects.json  (override with PROJECTS_FILE).

  Example .sync-projects.json:
    {
      "my-project": {
        "id": "<project-id-from-claude.ai-url>",
        "path": "projects/my-project"
      }
    }
  "path" is relative to BRAIN_DIR (or absolute). Find the id in the claude.ai
  URL when viewing the project: claude.ai/project/<project-id>.
"""
import sys, os, json, hashlib, argparse

BRAIN = os.environ.get("BRAIN_DIR", os.path.expanduser("~/brain"))
MANIFEST = os.path.join(BRAIN, ".sync-state.json")
PROJECTS_FILE = os.environ.get("PROJECTS_FILE", os.path.join(BRAIN, ".sync-projects.json"))
CONFLICT_MODE = os.environ.get("CONFLICT_MODE", "skip")  # skip | local-wins | keep-both


def load_projects() -> dict:
    if not os.path.exists(PROJECTS_FILE):
        sys.exit(
            f"No project config at {PROJECTS_FILE}.\n"
            "Create it: { \"my-project\": { \"id\": \"<project-id>\", "
            "\"path\": \"projects/my-project\" } }"
        )
    raw = json.load(open(PROJECTS_FILE, encoding="utf-8"))
    out = {}
    for key, cfg in raw.items():
        path = cfg["path"]
        if not os.path.isabs(path):
            path = os.path.join(BRAIN, path)
        out[key] = {"id": cfg["id"], "path": path}
    return out


PROJECTS = load_projects()


def h(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def load_manifest() -> dict:
    if os.path.exists(MANIFEST):
        return json.load(open(MANIFEST, encoding="utf-8"))
    return {}


def save_manifest(m: dict):
    json.dump(m, open(MANIFEST, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


def read_local(path: str) -> dict:
    out = {}
    if not os.path.isdir(path):
        return out
    for fn in os.listdir(path):
        if fn.endswith(".md"):
            fp = os.path.join(path, fn)
            c = open(fp, encoding="utf-8").read()
            out[fn] = {"content": c, "hash": h(c), "mtime": os.path.getmtime(fp)}
    return out


def read_remote(remote_path: str) -> dict:
    docs = json.load(open(remote_path, encoding="utf-8"))
    # accept both [{name,content}] and [{file_name,content}]
    out = {}
    for d in docs:
        name = d.get("name", d.get("file_name"))
        content = d.get("content", "")
        if name and name.endswith(".md"):
            out[name] = {"content": content, "hash": h(content)}
    return out


def decide(local: dict, remote: dict, base: dict) -> dict:
    actions = {"push": [], "pull": [], "conflict": [], "unchanged": []}
    for n in sorted(set(local) | set(remote)):
        L, R = local.get(n), remote.get(n)
        b = base.get(n, {}).get("hash")
        if L and not R:
            actions["push"].append(n)            # new locally
        elif R and not L:
            actions["pull"].append(n)            # new on claude.ai
        elif L["hash"] == R["hash"]:
            actions["unchanged"].append(n)
        else:
            lc, rc = (L["hash"] != b), (R["hash"] != b)
            if lc and not rc:
                actions["push"].append(n)
            elif rc and not lc:
                actions["pull"].append(n)
            else:
                actions["conflict"].append(n)    # both changed (or no base)
    return actions


def cmd_plan(proj: str, remote_path: str):
    cfg = PROJECTS[proj]
    local = read_local(cfg["path"])
    remote = read_remote(remote_path)
    base = load_manifest().get(proj, {})
    actions = decide(local, remote, base)

    # apply PULL: write pulled files locally
    os.makedirs(cfg["path"], exist_ok=True)
    pulled = []
    for n in actions["pull"]:
        fp = os.path.join(cfg["path"], n)
        open(fp, "w", encoding="utf-8").write(remote[n]["content"])
        pulled.append(n)

    # keep-both: write the remote side of a conflict next to it as name.remote.md
    if CONFLICT_MODE == "keep-both":
        for n in actions["conflict"]:
            fp = os.path.join(cfg["path"], n + ".remote.md")
            open(fp, "w", encoding="utf-8").write(remote[n]["content"])

    # local-wins: conflicts go into the push set
    push_names = list(actions["push"])
    if CONFLICT_MODE == "local-wins":
        push_names += actions["conflict"]

    # push payload for the agent
    push_payload = [{"name": n, "content": local[n]["content"]} for n in push_names]
    out_dir = os.path.dirname(os.path.abspath(remote_path))
    json.dump(push_payload, open(os.path.join(out_dir, "push.json"), "w", encoding="utf-8"),
              ensure_ascii=False)

    print(json.dumps({
        "project": proj, "conflict_mode": CONFLICT_MODE,
        "push": push_names, "pull": pulled,
        "conflict": actions["conflict"], "unchanged": actions["unchanged"],
        "push_json": os.path.join(out_dir, "push.json"),
    }, ensure_ascii=False, indent=2))


def cmd_commit(proj: str, remote_path: str):
    """After the agent applied pull+push, record the manifest for files that now
    match on both sides. Non-matching files (residual conflicts) are not recorded."""
    cfg = PROJECTS[proj]
    local = read_local(cfg["path"])
    remote = read_remote(remote_path)
    man = load_manifest()
    pm = man.get(proj, {})
    synced, residual = [], []
    for n in sorted(set(local) & set(remote)):
        if local[n]["hash"] == remote[n]["hash"]:
            pm[n] = {"hash": local[n]["hash"]}
            synced.append(n)
        else:
            residual.append(n)
    man[proj] = pm
    save_manifest(man)
    print(json.dumps({"project": proj, "committed": synced,
                      "residual_conflicts": residual, "manifest": MANIFEST},
                     ensure_ascii=False, indent=2))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["plan", "commit"])
    ap.add_argument("--proj", required=True, choices=list(PROJECTS))
    ap.add_argument("--remote", required=True)
    a = ap.parse_args()
    (cmd_plan if a.cmd == "plan" else cmd_commit)(a.proj, a.remote)
