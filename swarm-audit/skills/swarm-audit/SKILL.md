---
name: swarm-audit
description: |
  This skill should be used when the user asks to "audit the codebase", "review and fix codebase issues", "run a swarm audit", "security sweep", "type safety sweep", "codebase-wide review", or wants to spawn a multi-agent team to discover and fix issues across the codebase. Triggers on "swarm", "audit pipeline", "review pipeline", "team review", "parallel audit".
argument-hint: [scope] [--skip-browser] [--review-only]
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Task, TeamCreate, TeamDelete, TaskCreate, TaskUpdate, TaskGet, TaskList, SendMessage, AskUserQuestion
---

# Swarm Audit — Multi-Agent Codebase Review & Fix Pipeline

Orchestrate a discovery-first audit pipeline: **Review -> Triage -> Test -> Fix -> Verify**.

Unlike `/orchestrate` (which executes a pre-existing plan), this skill discovers issues from the codebase itself, triages them, optionally browser-tests, then fixes — all with parallel agents.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- `scope` — target path or "full" (default: full codebase)
- `--skip-browser` — skip browser testing phase
- `--review-only` — stop after review + triage, output report only

---

## Phase 1: Scope & Partition

Detect the project setup. Read `CLAUDE.md`, `package.json` or `pyproject.toml` for commands (type-check, lint, test). Read the project structure to partition the codebase into **non-overlapping review domains** (~5 domains).

For reference on partitioning strategies, read `references/review-domains.md`.

Present the proposed domains to the user for confirmation before spawning.

---

## Phase 2: Review (Parallel Agents)

Create a team with `TeamCreate`. Spawn one `code-audit-reviewer` agent per domain via the `Task` tool with `team_name`.

For reviewer prompt templates, read `references/team-prompts.md` (section: Reviewer Prompts).

Each reviewer:
1. Scans its file domain for issues (security, types, patterns, quality)
2. Returns structured findings: `{severity, file, line, description, fix_approach}`
3. Sends findings to the team lead via `SendMessage`

Launch ALL reviewers in a single message for maximum parallelism.

Wait for all reviewers to report back. Shut down each reviewer after it reports.

---

## Phase 3: Triage (Team Lead)

The team lead (main session) triages — no separate triage agents needed. For each finding:

1. **Validate** — Check the file/line exists, confirm the issue is real (quick `Read` or `Grep`)
2. **Deduplicate** — Merge overlapping findings from different reviewers
3. **Categorize** — Security, Type Safety, React Patterns, Performance, Dead Code
4. **Prioritize** — CRITICAL > HIGH > MEDIUM > LOW
5. **Batch** — Group related findings into tasks (one task per file or logical unit)

Create tasks with `TaskCreate`. Set `addBlockedBy` for dependencies (e.g., type definition task blocks consumer fix tasks). Present the triage summary to the user.

---

## Phase 4: Browser Test (Optional)

Skip if `--skip-browser` or no UI pages affected.

Spawn a single `task-executor` agent as `browser-tester`:
- Start dev server (`pnpm dev` or equivalent) on an available port
- Test affected pages via `curl -I` for auth enforcement (expect 302 redirects)
- Report results: PASS/FAIL per page
- Shut down after reporting

Update task priorities based on test results (e.g., promote auth failures to CRITICAL).

---

## Phase 5: Fix (Parallel Workers)

Assign each task to a worker domain. Spawn one `task-executor` agent per domain. For worker prompt templates, read `references/team-prompts.md` (section: Worker Prompts).

Worker rules:
- Read files before editing
- Run type-check after each fix batch
- Mark tasks completed via `TaskUpdate`
- Only touch files in assigned domain

**Load balancing:** Monitor `TaskList` periodically. When a worker finishes all its tasks:
- If pending tasks remain in other domains, spawn a new worker or reassign
- If no tasks remain, shut down the worker

---

## Phase 6: Verify

After all fix tasks complete:

```bash
pnpm type-check    # or: npx tsc --noEmit
pnpm lint
pnpm test:unit     # if available
```

If errors: launch a `quick-refactor` agent to fix type/lint errors. Rerun verification.

---

## Phase 7: Summary & Swarm Optimization

Output a structured report, then analyze the swarm execution itself and provide optimization suggestions.

```markdown
## Swarm Audit Results

**Scope:** [scope]
**Domains:** [N] review domains, [M] fix workers
**Tasks:** [completed]/[total]

### By Category
| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Security |    N     |  N   |   N    |  N  |
| Types    |    N     |  N   |   N    |  N  |
| ...      |    ...   | ...  |  ...   | ... |

### Verification
- Type check: PASS/FAIL
- Lint: PASS/FAIL
- Tests: PASS/FAIL (or skipped)

### Files Changed
[count] files modified, +[added]/-[removed] lines
```

### Swarm Optimization Report

After completing the audit, reflect on the swarm execution and output optimization suggestions. Track these metrics during the run, then analyze:

**Metrics to track:**
- Per-agent: tasks completed, idle time (messages sent while waiting), termination reason (done / out-of-turns / error)
- Per-domain: finding count, task count, fix count, false positive rate (findings invalidated during triage)
- Per-phase: wall-clock duration (time between first agent spawn and last agent shutdown)
- Task flow: reassignment count, cross-domain spillover count, blocked-task wait time

**Analysis to output:**

```markdown
### Swarm Optimization Suggestions

#### Agent Utilization
| Agent | Tasks | Idle Msgs | Termination | Utilization |
|-------|-------|-----------|-------------|-------------|
| reviewer-X | N | N | done/timeout | HIGH/MED/LOW |
| worker-Y | N | N | done/timeout | HIGH/MED/LOW |

**Bottleneck:** [Which agent(s) held up the pipeline? Which finished earliest?]
**Recommendation:** [Rebalance domains, split large domains, merge small ones]

#### Domain Balance
| Domain | Files | Findings | Tasks | Workers |
|--------|-------|----------|-------|---------|
| lib/ | N | N | N | N |
| settings/ | N | N | N | N |

**Skew:** [Which domain was over/under-served?]
**Recommendation:** [Adjust partition boundaries for next run]

#### Triage Efficiency
- Findings received: N
- False positives filtered: N (N%)
- Duplicates merged: N
- Tasks created: N

**Recommendation:** [If false positive rate >20%, refine reviewer prompts for that category. If duplicates >30%, reviewers have overlapping domains.]

#### Pipeline Throughput
- Review phase: ~N minutes (N agents)
- Triage phase: ~N minutes (lead only)
- Fix phase: ~N minutes (N workers)
- Verify phase: ~N minutes

**Bottleneck phase:** [Which phase took longest relative to its complexity?]
**Recommendation:** [e.g., "Triage took 40% of wall-clock time — consider spawning a triage assistant for large audits" or "Workers were underutilized — reduce to 3 next time"]

#### Worker Load Balancing
- Reassignments: N (tasks moved between workers)
- Spawned mid-run: N (new workers for large tasks)
- Early terminations: N (workers that ran out of turns)

**Recommendation:** [e.g., "worker-flow terminated mid-task on #41 (20 files) — cap task size at 10 files or spawn dedicated workers for large tasks upfront"]

#### Suggested Next Run Configuration
Based on this audit's data, the optimal configuration for a similar scope:
- **Reviewers:** N (adjust from current N)
- **Workers:** N (adjust from current N)
- **Domain split:** [Suggested new partition]
- **Model mix:** [e.g., "Use haiku for LOW-severity-only workers to reduce cost"]
- **Flags:** [e.g., "--skip-browser if no UI pages in scope"]
```

Shut down all remaining agents. Clean up the team with `TeamDelete`.

---

## Model Selection

| Role | Model | Agent Type |
|------|-------|------------|
| Reviewers | opus | code-audit-reviewer |
| Browser tester | haiku | task-executor |
| Workers | opus | task-executor |
| Quick fixes | haiku | quick-refactor |

---

## Error Handling

- If a reviewer fails: note the gap, continue with others, offer to re-review that domain
- If a worker terminates mid-task: reassign the incomplete task to a new worker
- If type-check fails after fixes: launch quick-refactor, do not ask the user unless it persists after 2 attempts
- If >50% of tasks fail: stop, present findings, ask the user for guidance

---

## Additional Resources

### Reference Files
- **`references/team-prompts.md`** — Agent spawn prompt templates for reviewers, workers, and browser testers
- **`references/review-domains.md`** — Codebase partitioning strategies by framework and project type
- **`references/optimization.md`** — Metrics collection schema, optimization heuristics, anti-patterns from past runs, and suggested run configurations
