# Swarm Optimization Reference

## Metrics Collection

Track these during each phase. Store in-memory as the run progresses.

### Agent Metrics
```
agent_metrics = {
  "agent_name": {
    "role": "reviewer|worker|tester",
    "domain": "lib/|settings/|...",
    "tasks_completed": 0,
    "tasks_failed": 0,
    "idle_notifications": 0,        # count of idle pings before shutdown
    "messages_sent": 0,
    "messages_received": 0,
    "termination": "done|timeout|error|reassigned",
    "spawn_time": "HH:MM:SS",
    "shutdown_time": "HH:MM:SS",
  }
}
```

### Phase Metrics
```
phase_metrics = {
  "review":  { "start": T, "end": T, "agents": N, "findings": N },
  "triage":  { "start": T, "end": T, "findings_in": N, "tasks_out": N, "false_positives": N, "duplicates": N },
  "browser": { "start": T, "end": T, "tests": N, "pass": N, "fail": N },
  "fix":     { "start": T, "end": T, "agents": N, "tasks_completed": N, "reassignments": N },
  "verify":  { "start": T, "end": T, "type_check": "pass|fail", "lint": "pass|fail", "test": "pass|fail|skip" },
}
```

### Task Flow Metrics
```
task_metrics = {
  "total_created": 0,
  "by_severity": { "CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0 },
  "by_category": { "security": 0, "types": 0, "patterns": 0, "quality": 0 },
  "reassigned": 0,          # tasks moved between workers
  "blocked_wait": 0,        # tasks that waited on dependencies
  "cross_domain": 0,        # tasks requiring files from multiple domains
}
```

---

## Optimization Heuristics

### When to add more workers
- A domain has >15 tasks AND other workers are idle
- A single task covers >10 files (spawn a dedicated worker)
- Worker terminates mid-task (out of turns) — task was too large

### When to reduce workers
- Worker completes all tasks in <2 minutes with no reassignments
- Domain produced <3 tasks total
- Multiple workers sitting idle waiting for blocked tasks

### When to adjust domains
- One domain produces 3x+ more findings than others → split it
- Two domains produce <5 findings combined → merge them
- Cross-domain tasks appear (files from multiple domains) → redraw boundaries

### When to adjust reviewer prompts
- False positive rate >20% for a category → tighten criteria in prompt
- Reviewer misses issues that workers discover during fixes → expand checklist
- Duplicate findings >30% between reviewers → domains overlap, tighten scope

### Model cost optimization
- LOW-severity-only tasks → use haiku workers (cheaper, faster)
- CRITICAL/HIGH security tasks → always opus (accuracy matters)
- Browser testing → haiku (just curl commands)
- Quick-refactor (lint/type fixes) → haiku (mechanical changes)

---

## Common Anti-Patterns from Past Runs

### 1. Cramming overflow onto busy workers
**Problem:** When a worker finishes early, reassigning 5+ tasks from another domain overloads it.
**Fix:** Spawn a new worker for the overflow domain instead. Fresh context = fewer errors.

### 2. Separate triage agents
**Problem:** 3 triage agents created overhead (spawning, messaging, coordination) for what amounts to list filtering.
**Fix:** Lead does triage inline. Only spawn triage agents if >100 findings need parallel validation.

### 3. Heavyweight browser testing
**Problem:** Full browser automation (Puppeteer/Playwright) is slow and fragile in CI-less environments.
**Fix:** `curl -I` for auth enforcement (302 checks) covers 80% of value. Only escalate to full browser for post-login rendering tests.

### 4. Pre-allocating all workers at spawn
**Problem:** If review finds fewer issues than expected, workers sit idle.
**Fix:** Spawn workers after triage, sized to actual task count.

### 5. Not capping task size
**Problem:** A "fix all any types in flow-builder" task (20 files) exceeds agent turn limits.
**Fix:** Cap tasks at ~10 files. Split larger tasks into subtasks during triage.

---

## Suggested Run Configurations

### Quick Security Audit
```
/swarm-audit --skip-browser
Reviewers: 2 (server-actions, pages)
Workers: 2
Focus: auth, tenant isolation, permissions only
```

### Full Type Safety Sweep
```
/swarm-audit lib/ components/
Reviewers: 3 (lib, components, flow-builder)
Workers: 3
Focus: any types, Zod schemas, type guards
```

### Pre-Deploy Full Audit
```
/swarm-audit
Reviewers: 5 (full partition)
Workers: 5
Browser: enabled
All categories
```
