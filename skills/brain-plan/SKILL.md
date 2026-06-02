---
name: brain-plan
description: >
  Creates a detailed step-by-step execution plan for a task, using the project's wiki
  as context. Use this skill when the user wants to plan work, break a task into steps,
  or prepare before executing. Triggers on: "plan this", "create a plan",
  "break this into steps", "what's the plan for", "plan before we start",
  "планирование", "составь план", "разбей на шаги".
  Always use this skill BEFORE brain-run — plan first, execute second.
---

# brain-plan

Creates a structured execution plan in `plans/` using wiki context for grounding.

## When to use

Before any non-trivial task. brain-plan → brain-run is the standard flow.

## What it does

1. Extracts the task topic and calls `/wiki <topic>` to load only relevant wiki files (saves ~60% context vs loading all wiki)
2. Checks `known-issues.md` for relevant blockers
3. Spawns a Plan agent with wiki context
4. Creates `plans/<YYYY-MM-DD>_<slug>.md` with steps, files, criteria, parallelism
5. Creates TaskList entries for each step

## Plan file structure

```markdown
# <Task name>
> Created: <date> | Status: 🔄 In progress

## Goal
<one sentence>

## Done criteria
<how to verify completion>

## Steps

### Step 1 — <name>
- **Agent:** general-purpose
- **Files:** <list>
- **Result:** <what changes>
- **Check:** <how to verify>
- **Status:** [ ] Not started

## Parallel steps
<which steps can run simultaneously>

## Risks
- <risk>: <mitigation>

## Execution log
```

## Topic keywords

The `/brain-plan` command extracts a topic keyword from the task description before calling `/wiki`.
The keyword-to-file mapping lives in `commands/brain-plan.md` and should be customized per project.

Default pattern (adapt to your stack):
```
auth, login, session    → auth
database, migration     → database
api, endpoint           → api
render, component, ui   → frontend
deploy, build, ci       → devops
test, spec              → testing
bugs, issues            → known-issues.md
```

## Output

Always end with STOP — brain-plan only creates the plan, never executes it.
Tell the user: "Plan created at plans/<filename>.md. Run brain-run when ready."
