---
name: orchestrate
description: Orchestrate multi-stage refactors from an RCA or plan document. Use when implementing a phased refactoring plan with dependencies between stages.
argument-hint: <path-to-rca-or-plan-file>
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, Bash
---

# Multi-Stage Refactor Orchestrator

## Input

Plan/RCA file: $ARGUMENTS

## Your Role

Orchestrate a multi-stage refactoring project. Execute these phases in order:

## Phase 1: Plan Analysis

Read the provided file and extract:

1. **Stages** - Each distinct phase of work
2. **Files per stage** - What each stage modifies
3. **Dependencies** - Which stages block others
4. **Acceptance criteria** - How to verify completion

Create a dependency diagram showing parallel vs sequential stages.

## Phase 2: Codebase Detection

Detect the project setup:

```bash
# Detect package manager / language
if [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
elif [ -f "yarn.lock" ]; then echo "yarn"
elif [ -f "package-lock.json" ]; then echo "npm"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then echo "python"
else echo "unknown"
fi
```

Read `package.json` or `pyproject.toml` to find type-check, lint, and test commands.

## Phase 3: Current State Assessment

Launch **parallel Explore agents** to check each stage's status:

```
Task tool:
  subagent_type: Explore
  model: opus
  prompt: Check if Stage N changes exist...
```

Determine: `COMPLETE` | `PARTIAL` | `NOT_STARTED`

Output status table and skip completed stages.

## Phase 4: Task Creation

For each incomplete stage, use TaskCreate:

```
Subject: Stage N: [brief description]
Description: Files, changes, acceptance criteria
ActiveForm: [Present continuous phrase]
```

Set dependencies with TaskUpdate `addBlockedBy`.

## Phase 5: Parallel Execution

Launch **opus task-executor agents** for independent stages:

```
Task tool:
  subagent_type: task-executor
  model: opus
```

**Rules:**
- Independent stages → single message with multiple Task calls
- Same-file stages → run sequentially
- Mark tasks `in_progress` before launching

**Agent prompt must include:**
- Context from plan
- Specific files and changes
- Acceptance criteria
- Instruction to read files before editing

## Phase 6: Sequential Stages

After parallel stages complete:

1. TaskUpdate to mark completed
2. TaskList to find unblocked stages
3. Launch agents for newly unblocked work
4. Repeat until done

## Phase 7: Verification

**Node.js/TypeScript:**
```bash
[npm|pnpm|yarn] run type-check   # or: npx tsc --noEmit
[npm|pnpm|yarn] run lint
[npm|pnpm|yarn] test
```

**Python:**
```bash
mypy . || pyright
ruff check . || flake8
pytest
```

If errors: launch `quick-refactor` agent (opus) to fix type errors, investigate test failures.

## Phase 8: Documentation

Update the original plan file:

```markdown
---

## Implementation Status

**Completed:** [date]

### Stage 1: [name] ✅
- Files modified: [list]

### Verification Results
- Type check: ✅
- Lint: ✅
- Tests: ✅
```

## Model Selection

| Task | Model | Subagent |
|------|-------|----------|
| Assessment | opus | Explore |
| Implementation | opus | task-executor |
| Quick fixes | opus | quick-refactor |

## Error Handling

If a stage fails:
1. Keep task `in_progress`
2. Create blocker task
3. Continue non-dependent stages
4. Ask user if unclear
