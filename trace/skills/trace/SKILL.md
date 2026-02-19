---
name: trace
description: Map codebase dependencies with tree and reading order
argument-hint: [--entry-point PATH] [--filter DIR] [--depth N]
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# /trace

Map codebase from entry points to leaves. Output dependency tree + numbered reading order.

## Args

- `--entry-point` - Start file (default: auto-detect main.py/app.py/index.ts)
- `--filter` - Limit to directory
- `--depth` - Max levels (default: unlimited)

## Process

1. Find entry points via Glob
2. Extract imports via Grep (`^from|^import`)
3. Build dependency graph
4. Order: leaves first, entry points last

## Output

**Tree:**
```
main.py
├── app.py
│   ├── handlers/api.py
│   │   └── agents/orchestrator.py
│   └── slack/events.py
└── config.py
```

**Reading Order:**
```
 1. config.py              settings
 2. core/logging.py        infrastructure
 3. clients/bq.py          external client
 4. agents/base.py         core logic
 5. agents/bq/tools.py     implementation
 6. agents/orchestrator.py main agent
 7. handlers/api.py        HTTP layer
 8. app.py                 entry point
```
