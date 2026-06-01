---
name: brain-run
description: >
  Executes the active plan from plans/ using subagents, with wiki context injected
  per step. Use this skill when the user wants to execute a plan, run steps, or
  continue work. Triggers on: "run the plan", "execute", "rabota", "start working",
  "do the steps", "run step N", "выполни план", "запускай", "работа по плану".
  Always use brain-plan first to create the plan, then brain-run to execute it.
---

# brain-run

Executes the active plan step by step using subagents, grounded in wiki context.

## Flow

1. Find active plan (`🔄 In progress` status in `plans/`)
2. For each pending step — load `/wiki <topic>` + relevant `known-issues.md` entries
3. Show execution graph, wait for user confirmation
4. Spawn subagents (parallel where possible, sequential where required)
5. Verify results (TypeScript/lint diagnostics, git diff)
6. Save findings to `solutions.md` and `known-issues.md`
7. Update plan file statuses

## Step statuses

| Mark | Meaning |
|------|---------|
| `[ ]` | Not started |
| `[x]` | Completed — verified, no errors |
| `[~]` | Partial — errors found |
| `[!]` | Blocked — needs new plan |

## After execution

For each step, agents report back:
- **For solutions.md** — non-trivial problems found and solved
- **For .raw_nuances.md** — architectural invariants, non-obvious patterns

Append these to the project wiki immediately after the step completes.
wiki-push runs automatically via wiki-watch (or run manually: `python wiki-push.py`).

## When a step is blocked

Mark `[!]`, surface the blocker clearly, suggest:
"Use brain-plan to create a plan for this blocker: <description>"

## Modes

| Command | Action |
|---------|--------|
| `brain-run` | All pending steps of active plan |
| `brain-run step 2 3` | Only steps 2 and 3 |
| `brain-run check` | Credit direct edits made outside brain-run |
