---
description: Compare a file across all worktrees and consolidate changes
allowed-tools: Task
argument-hint: <subpath> [worktrees-dir]
---

Use the Task tool to invoke the `worktree-diff` agent with:
- baseline: `$1` (file path relative to current project)
- worktrees_dir: `$2` (defaults to `~/.cursor/worktrees/dynamic-pricing`)

The agent will compare the file across all worktrees, collect changes, deduplicate, and return a consolidated review.
