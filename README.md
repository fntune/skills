# Skills

Claude Code skills for TypeScript tooling, codebase auditing, design exploration, and refactoring orchestration.

Follows the [Agent Skills](https://agentskills.io/) format.

## Available Skills

### ts-strict

Migrate a codebase to strict TypeScript and Biome lint rules using an infrastructure-first approach. Treats type errors as symptoms of missing type architecture, not individual problems.

**Use when:** "enable strict", "strict mode", "fix type safety", "tighten types", "noExplicitAny", "strict biome"

**Phases:** Baseline (per-flag error counts) → Audit (root cause categories) → Fix (type infrastructure) → Enable (flags + Biome rules) → Clean

**Includes:** Drizzle + Zod v4 full-stack type propagation, monorepo considerations, 11 audit categories, fix patterns for every category.

### design-exploration

Generate N distinct visual design variants of a page by spawning parallel agents. Each variant is a self-contained page file with a unique aesthetic direction.

**Use when:** "design exploration", "design variants", "parallel designs", "generate N designs"

### orchestrate

Execute multi-stage refactoring plans with dependency tracking between stages. Takes an RCA or plan document as input and runs stages in topological order.

**Use when:** implementing a phased refactoring plan with dependencies between stages

### swarm-audit

Multi-agent codebase review and fix pipeline. Discovers issues from the codebase itself, triages them, then fixes — all with parallel agents.

**Use when:** "audit the codebase", "swarm audit", "security sweep", "type safety sweep", "codebase-wide review"

**Pipeline:** Review → Triage → Test → Fix → Verify

### trace

Map codebase dependencies from entry points to leaves. Outputs a dependency tree and numbered reading order.

**Use when:** "trace dependencies", "map codebase", "reading order", "dependency tree"

### utils

Slash commands and subagents for everyday workflows.

**Commands:**

| Command | Description |
|---|---|
| `/ask` | Gather decisions via structured questions with tradeoff analysis |
| `/commit-push` | Commit and push changes to current branch |
| `/debloat` | Remove AI slop and unnecessary code |
| `/dry` | Find DRY violations — duplicated logic, repeated patterns |
| `/lint` | Run and report lint results |
| `/triage` | Review issues against code, identify patterns, plan fixes |
| `/update-claude` | Update CLAUDE.md based on conversation discoveries |
| `/web-interface-guidelines` | Review UI code for Vercel Web Interface Guidelines compliance |
| `/worktree-diff` | Compare a file across all worktrees and consolidate changes |

**Agents:**

| Agent | Description |
|---|---|
| `code-audit-reviewer` | Systematic code review against specs, catches AI-introduced issues |
| `quick-refactor` | Fast mechanical refactoring — renames, moves, reformats |
| `task-executor` | Precise execution of well-defined tasks without deviation |

## Installation

### Claude Code (native plugin)

```bash
# Add marketplace
claude plugin marketplace add fntune/skills

# Install a skill
claude plugin install ts-strict@fntune-skills
claude plugin install utils@fntune-skills
```

### Cross-agent (skills.sh)

Works with Claude Code, Codex CLI, Gemini CLI, and others:

```bash
npx skills add fntune/skills@ts-strict
```

## Structure

Each plugin can contain:

```
<plugin>/
  .claude-plugin/plugin.json   # Plugin manifest
  skills/<name>/SKILL.md       # Skills (contextual helpers)
  commands/<name>.md            # Slash commands
  agents/<name>.md              # Subagent definitions
  references/                   # Supporting docs (optional)
```

## License

MIT
