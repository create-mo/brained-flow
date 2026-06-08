/* brain-sync v2 — in-page bridge
 *
 * These functions run INSIDE a logged-in claude.ai tab (via Claude in Chrome →
 * javascript_tool). The browser automatically attaches the httpOnly `sessionKey`
 * cookie to every same-origin fetch, so you never read, store, or decrypt any
 * key. Chrome's App-Bound Encryption (cookie v20, Chrome 127+) is irrelevant
 * here — instead of extracting the cookie, we work inside the session that
 * already owns it.
 *
 * Why this exists: the original sessionKey scripts (wiki-push.py / wiki-pull.py)
 * need you to copy the cookie out of the browser. On Chrome 127+ that cookie is
 * sealed by App-Bound Encryption and can no longer be read programmatically.
 * This bridge sidesteps the problem entirely.
 *
 * Endpoints mirror the sessionKey scripts:
 *   GET|POST  /api/organizations/{org}/projects/{project}/docs
 *   DELETE    /api/organizations/{org}/projects/{project}/docs/{uuid}
 * Fields: file_name, content, uuid.
 *
 * REPL note: top-level await does NOT work in javascript_tool. Wrap calls in an
 * async IIFE that returns a string, e.g.:
 *   (async () => JSON.stringify(await pull("<your-project-id>")))()
 *
 * Find your Project ID in the claude.ai URL: claude.ai/project/<project-id>
 */

// Org ID is resolved at runtime from the logged-in session — nothing hardcoded.
let _orgId = null;
async function orgId() {
  if (_orgId) return _orgId;
  const orgs = await (await fetch("/api/organizations", { credentials: "include" })).json();
  _orgId = orgs[0].uuid;
  return _orgId;
}

async function docsBase(projectId) {
  return `/api/organizations/${await orgId()}/projects/${projectId}/docs`;
}

// PULL: return every doc in a Project as [{name, content, id, created}]
async function pull(projectId) {
  const base = await docsBase(projectId);
  const docs = await (await fetch(base, { credentials: "include" })).json();
  return docs.map((d) => ({
    name: d.file_name,
    content: d.content,
    id: d.uuid,
    created: d.created_at,
  }));
}

// PUSH (upsert one file): claude.ai cannot edit docs in place — delete the old
// one, then create the new one. Returns the created document.
async function push(projectId, fileName, content) {
  const base = await docsBase(projectId);
  const docs = await (await fetch(base, { credentials: "include" })).json();
  const existing = docs.find((d) => d.file_name === fileName);
  if (existing) {
    await fetch(`${base}/${existing.uuid}`, { method: "DELETE", credentials: "include" });
  }
  const res = await fetch(base, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ file_name: fileName, content }),
  });
  if (!res.ok) throw new Error(`push ${fileName} → ${res.status}`);
  return await res.json();
}

// Batch push: files = [{name, content}, ...]
async function pushMany(projectId, files) {
  const out = [];
  for (const f of files) {
    out.push({ name: f.name, ok: true, ...(await push(projectId, f.name, f.content)) });
  }
  return out;
}
