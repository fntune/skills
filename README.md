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

## Installation

Install all skills:

```bash
npx skills add fntune/skills
```

Install a single skill:

```bash
npx skills add fntune/skills@ts-strict
```

## Skill Structure

Each skill directory contains:

- `SKILL.md` — Agent instructions with YAML frontmatter (name, description, triggers)
- `references/` — Supporting documentation loaded on demand (optional)

## License

MIT
