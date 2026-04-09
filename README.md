# fntune/skills

> Claude Code plugin marketplace — specialized agents, slash commands, and workflow automation for developers.

```bash
# Claude Code
claude plugin marketplace add fntune/skills
claude plugin install ts-strict@fntune-skills

# Any agent (Claude Code, Codex CLI, Gemini CLI, ...)
npx skills add fntune/skills
```

Six focused plugins. Install only what you need.

---

## Plugins

### ts-strict — TypeScript strict mode migration

Migrates a codebase to `strict: true` and Biome lint rules using an infrastructure-first strategy: fix the type architecture first, then enable the flags — instead of whack-a-mole on 10,000 individual errors.

**Phases:** Baseline → Audit (11 error categories) → Fix type infrastructure → Enable strict flags + Biome → Clean

**What it handles:**
- Categorizes type errors by root cause (missing generics, implicit `any`, unsafe assertions, missing return types, etc.)
- Full-stack type propagation with Drizzle ORM + Zod v4 patterns
- Monorepo-aware (Turborepo, pnpm workspaces)

**Triggers:** "enable strict", "strict mode", "fix type safety", "tighten types", "noExplicitAny"

---

### swarm-audit — Multi-agent codebase review and fix

Discovers issues from the codebase itself, triages them, then fixes — all with parallel agents. You don't define the rules; the agents find the problems.

**Pipeline:**
1. **Review** — partitions codebase into domains, spawns parallel reviewer agents per domain
2. **Triage** — team lead deduplicates and prioritizes findings
3. **Test** — optionally checks UI pages after changes (browser-tester agent)
4. **Fix** — parallel task-executor agents fix issues, domain-assigned
5. **Verify** — type-check, lint, tests

**Use for:** security sweeps, type safety audits, code quality passes, pre-release reviews

**Triggers:** "audit the codebase", "swarm audit", "security sweep", "codebase-wide review"

---

### orchestrate — Multi-stage refactoring executor

Takes an RCA or plan document as input, resolves stage dependencies, and executes the plan with parallel agents and task tracking.

**What it does:**
- Reads stage definitions and `depends_on` edges from a plan doc
- Spawns parallel Explore agents to assess current state per stage
- Creates a `TaskCreate` tree with dependency tracking (`addBlockedBy`)
- Launches task-executor agents for incomplete stages
- Verifies with type-check, lint, tests on completion
- Updates the plan doc with status

**Use for:** large refactors with an existing plan document, phased migrations, multi-PR work

**Triggers:** implementing a phased plan with stage dependencies

---

### design-exploration — Parallel design variants

Spawns N agents in parallel, each producing one self-contained page variant with a distinct aesthetic direction. All run simultaneously — you get N variants in the time it takes to generate one.

**Output:** each variant is a standalone page file with its own styles and layout, ready to compare side by side.

**Triggers:** "design exploration", "design variants", "parallel designs", "generate N designs"

---

### trace — Dependency tree mapper

Maps codebase dependencies from entry points to leaves. Outputs a dependency tree and a numbered reading order (leaves first, entry last). Uses only Grep, Glob, and Read — no model calls, instant results.

**Output:**
- Nested dependency tree from entry point to all leaves
- Numbered reading order for onboarding or refactoring planning

**Use for:** onboarding to a new codebase, understanding what to read before moving files

**Triggers:** "trace dependencies", "map codebase", "reading order", "dependency tree"

---

### utils — Slash commands and subagents for everyday workflows

Nine slash commands and three subagents for common developer tasks.

**Slash commands:**

| Command | What it does |
|---------|-------------|
| `/ask` | Structured decision gathering with tradeoff analysis |
| `/commit-push` | Commit and push the current branch |
| `/debloat` | Remove AI slop and unnecessary code |
| `/dry` | Find DRY violations — duplicated logic, repeated patterns |
| `/lint` | Run linter and report results |
| `/triage` | Review issues against code, identify patterns, plan fixes |
| `/update-claude` | Update CLAUDE.md from conversation discoveries |
| `/web-interface-guidelines` | Check UI code against Vercel Web Interface Guidelines |
| `/worktree-diff` | Compare a file across all worktrees and consolidate changes |

**Subagents:**

| Agent | What it does |
|-------|-------------|
| `code-audit-reviewer` | Systematic code review against specs; catches AI-introduced issues, missing error handling, and inconsistencies |
| `quick-refactor` | Fast mechanical refactoring — renames, moves, reformats, import updates |
| `task-executor` | Precise execution of well-defined tasks without deviation or interpretation |

---

## Installation

### Claude Code (native plugin)

```bash
# Add the marketplace once
claude plugin marketplace add fntune/skills

# Install individual plugins
claude plugin install ts-strict@fntune-skills
claude plugin install utils@fntune-skills
claude plugin install swarm-audit@fntune-skills
claude plugin install design-exploration@fntune-skills
claude plugin install orchestrate@fntune-skills
claude plugin install trace@fntune-skills
```

### Cross-agent (skills.sh)

Works with Claude Code, Codex CLI, Gemini CLI, and [30+ other agents](https://skills.sh/):

```bash
# All skills
npx skills add fntune/skills

# Single skill
npx skills add fntune/skills@ts-strict
npx skills add fntune/skills@swarm-audit
```

---

## Plugin structure

```
<plugin>/
  .claude-plugin/plugin.json    manifest (name, version, description, triggers)
  skills/<name>/SKILL.md        contextual knowledge — loaded when relevant
  commands/<name>.md            slash commands — user-invokable actions
  agents/<name>.md              subagents — delegated task specialists
```

---

## License

MIT
