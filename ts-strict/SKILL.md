---
name: ts-strict
description: >
  Enable TypeScript strict mode and Biome strict lint rules in an existing codebase using an
  infrastructure-first strategy. Use when the user asks to: enable strict TypeScript, configure
  Biome strict linting, fix type safety, migrate to strict mode, enable noExplicitAny /
  noUnusedVariables / noNonNullAssertion, or tighten type checking. Triggers on: "enable strict",
  "strict mode", "strict types", "strict biome", "biome strict", "fix type safety",
  "tighten types", "noExplicitAny".
---

# TypeScript Strict Migration

Migrate a codebase to strict TypeScript and Biome lint rules using an infrastructure-first approach.
Treat type errors as symptoms of missing type architecture, not individual problems.

## Strategy: Infrastructure First, Rules Last

```
0. Baseline -> Measure tsc --strict errors per flag
1. Audit    -> Identify patterns producing `any` and weak types
2. Fix      -> Define interfaces, replace raw queries, fix return types
3. Enable   -> Turn on tsconfig flags incrementally, then Biome rules
4. Clean    -> Fix remaining localized issues
```

Never do bulk mechanical replacements (`any` -> `Record<string, unknown>`). That trades one
form of "I don't know the type" for another and creates cascading downstream errors.

## Phase 0: Baseline

Measure current error counts per strict flag before touching any code:

```bash
# Total strict errors
tsc --noEmit --strict 2>&1 | tail -1

# Per-flag breakdown (strict family)
tsc --noEmit --noImplicitAny 2>&1 | tail -1
tsc --noEmit --strictNullChecks 2>&1 | tail -1
tsc --noEmit --strictFunctionTypes 2>&1 | tail -1
tsc --noEmit --strictPropertyInitialization --strictNullChecks 2>&1 | tail -1

# Beyond-strict flags (not included in strict: true)
tsc --noEmit --noUncheckedIndexedAccess 2>&1 | tail -1
```

Note: `strictPropertyInitialization` requires `strictNullChecks` to be meaningful.

Present a table and get user approval on enable order:

| Flag | Errors | Recommended order |
|---|---|---|
| `noImplicitAny` | N | 1st — easiest wins |
| `strictNullChecks` | N | 2nd — biggest safety gain |
| `strictFunctionTypes` | N | 3rd — usually few errors |
| `strictPropertyInitialization` | N | 4th — class-heavy codebases |
| Full `strict: true` | N | Last — enables all remaining |

`strict: true` also enables `strictBindCallApply`, `noImplicitThis`, `alwaysStrict`, and
`useUnknownInCatchVariables` — these rarely produce many errors but measure them if the
gap between individual flags and full `strict` is large.

Beyond strict (not included in `strict: true` — must remain as separate flags):

| Flag | Purpose |
|---|---|
| `noUncheckedIndexedAccess` | `arr[0]` and `obj[key]` return `T \| undefined` — highest friction, biggest safety gain after `strictNullChecks` |
| `exactOptionalPropertyTypes` | `{ a?: string }` distinguishes "missing" from "explicitly `undefined`" |
| `noUncheckedSideEffectImports` | Errors on unresolvable side-effect imports like `import "./missing"` (TS 5.6+) |

## Phase 1: Audit

Catalog every `any` and weak type by root cause category. See
[references/audit-categories.md](references/audit-categories.md) for the common categories.

```bash
# Count current violations before touching anything
biome lint . 2>&1 | grep -c 'noExplicitAny'
biome lint . 2>&1 | grep -c 'noUnusedVariables'
```

Group violations by file and root cause. Present a summary table:

| Root cause | Count | Fix approach |
|---|---|---|
| Untyped API responses | N | Define response interfaces |
| Raw SQL / `db.execute()` | N | Replace with typed ORM queries |
| `Partial<T>` too loose | N | Use `Pick<T, ...>` for known fields |
| External JWT/webhook payloads | N | Validate at boundary with Zod (or `typeof`) |
| Callback params | N | Type the callback signature |
| Unused `_`-prefixed params | N | Configure rule to ignore `^_` pattern |

Get user approval on the plan before proceeding.

## Phase 2: Fix Type Infrastructure

Work through root causes from highest-impact to lowest. For each category:

1. **Define the missing type** at its source (API client, ORM query, service layer)
2. **Verify downstream usage compiles** without casts or bandaids
3. **Run build** to confirm no regressions

### Patterns by category

See [references/fix-patterns.md](references/fix-patterns.md) for detailed patterns covering:
- API response interfaces
- ORM typed queries (Drizzle, Prisma)
- External data boundary validation
- Return type tightening (`Partial` -> `Pick`)
- Callback and event handler typing
- `satisfies` for config/literal objects
- Discriminated union exhaustiveness (`assertExhaustive`)

For Drizzle + Zod v4 full-stack type propagation (DB schema → API contracts → frontend),
see [references/drizzle-zod.md](references/drizzle-zod.md).

### Principles

- Fix the type at its **source**, not at its usage site
- Every `as X` cast or `?? fallback` at a usage site signals a missing upstream type
- Prefer `typeof` narrowing over type assertions for external data
- Use `Pick<T, fields>` over `Partial<T>` when you know which fields are selected
- Replace raw SQL with typed ORM queries whenever the ORM supports it

## Phase 3: Enable Rules

Only after infrastructure fixes are in place.

### 3a. tsconfig strict flags

Enable flags incrementally in the order from Phase 0. After each flag:
1. Add the flag to `tsconfig.json`
2. Run `tsc --noEmit` — fix any new errors
3. Commit before enabling the next flag

Once all individual flags pass, switch to `"strict": true` and remove the individual strict-family
flags. Keep beyond-strict flags (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, etc.)
as separate entries — they are not included in `strict: true`.

### 3b. Biome strict rules

Biome is a single Rust binary that handles linting and formatting — no plugins, no tsc dependency.
Its `recommended` preset enables a sensible baseline (style rules default to `warn`; override to
`error` for strict enforcement).

Key rules for strict TypeScript:

| Rule | Category | What it catches |
|---|---|---|
| `noExplicitAny` | suspicious | Explicit `any` type annotations |
| `noUnusedVariables` | correctness | Unused variables and type params |
| `noUnusedImports` | correctness | Unused import statements |
| `noUnusedFunctionParameters` | correctness | Unused function parameters |
| `noNonNullAssertion` | style | `!` postfix assertions |
| `useConst` | style | `let` where `const` suffices |
| `useImportType` | style | Missing `import type` for type-only imports |
| `noFloatingPromises` | types | Unawaited promises (v2.4+, type-aware) |

**Type-aware rules**: Biome v2 added file scanning for type inference. Rules that need type info
live in the `types` domain (v2.4+; earlier versions used `project`). Currently `noFloatingPromises`
is the main type-aware rule. Deep type-checked rules like `no-unsafe-assignment` and
`no-unnecessary-type-assertion` don't have Biome equivalents yet — `tsc --noEmit` with strict
flags covers the type safety that Biome can't.

Strict production config with test file overrides:

```json
{
  "$schema": "https://biomejs.dev/schemas/<version>/schema.json",
  "linter": {
    "rules": {
      "recommended": true,
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error",
        "noUnusedFunctionParameters": "error"
      },
      "suspicious": {
        "noExplicitAny": "error",
        "noDoubleEquals": "error"
      },
      "style": {
        "noNonNullAssertion": "error",
        "useConst": "error",
        "useImportType": "error"
      }
    }
  },
  "overrides": [
    {
      "includes": ["**/__tests__/**", "**/*.test.ts", "**/*.test.tsx"],
      "linter": {
        "rules": {
          "suspicious": { "noExplicitAny": "off" },
          "style": { "noNonNullAssertion": "off" },
          "complexity": { "noBannedTypes": "off" }
        }
      }
    }
  ]
}
```

After enabling:
1. Run `biome lint .` — expect most violations already resolved from Phase 2
2. Run `biome lint --write .` for auto-fixable issues (unused imports, `let` → `const`, etc.)

### Suppression guidance

**TypeScript**:
- Never use `@ts-ignore` — it silently persists after the underlying error is fixed
- Use `@ts-expect-error` with a description when suppression is genuinely needed:
  ```typescript
  // @ts-expect-error -- library types don't expose the overload we need
  ```
  `@ts-expect-error` errors when the suppressed issue disappears, preventing stale suppressions

**Biome** — reason is mandatory (Biome rejects bare suppressions):
```typescript
// biome-ignore lint/suspicious/noExplicitAny: legacy API requires any
const result: any = legacyFunction();
```

### Monorepo considerations

In a multi-package repo, strict migration touches shared config infrastructure:

**Shared base tsconfig** — define strict flags once in a root `tsconfig.base.json`, have every
package extend it. Redundantly repeating `"strict": true` in per-package configs is fine as an
explicit marker, but the actual flag set should live in one place.

```json
// tsconfig.base.json (root)
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "isolatedModules": true,
    "moduleResolution": "bundler"
  }
}
```

```json
// packages/foo/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": { "outDir": "./dist", "rootDir": "./src" },
  "include": ["src/**/*"]
}
```

**Biome in monorepos** — a single root `biome.json` applies to all packages automatically.
No per-package config needed. Use `overrides` with `includes` globs for package-specific
rule relaxation (e.g., animation packages, generated code).

**Cross-package type resolution** — two strategies, pick one:

1. **Build-first (Turborepo/Nx)**: upstream packages build `.d.ts` into `dist/`, downstream
   packages consume them via `package.json` `"types"` field. Typecheck task depends on
   `^build` (upstream builds run first). No project references needed.

2. **Project references (`tsc --build`)**: set `composite: true` in each package tsconfig,
   add a `"references"` array in the root. Faster incremental builds but more config overhead.

Most Turborepo/Bun/pnpm monorepos use strategy 1. Project references are mainly useful when
you want single-command `tsc --build` without a task runner.

**Baseline per-package**: in Phase 0, measure errors per package to find the worst offenders:

```bash
# Run from monorepo root
for pkg in packages/*/; do
  echo "=== $pkg ==="
  tsc --noEmit --project "$pkg/tsconfig.json" --strict 2>&1 | tail -1
done
```

**Enable flags root-first**: add the flag to `tsconfig.base.json`, then fix errors package by
package (core/utils first, then infrastructure, then domain, then frontend). This follows the
dependency graph — fixing upstream packages eliminates cascading errors downstream.

**Selective typecheck configs**: for large packages with generated or third-party code (e.g.,
shadcn components), create a `tsconfig.typecheck.json` that narrows `include` to your code only:

```json
// packages/ui/tsconfig.typecheck.json
{
  "extends": "./tsconfig.json",
  "include": ["src/auth/**", "src/billing/**"],
  "exclude": ["src/primitives/**", "src/composed/**"]
}
```

Then in `package.json`: `"typecheck": "tsc --noEmit --project tsconfig.typecheck.json"`.

## Phase 4: Clean Remaining Issues

Fix remaining violations individually. These should be localized (not cascading) because
the type infrastructure is already correct. Common remaining fixes:

- Remove truly dead code (unused variables without `_` prefix)
- Add `_` prefix to intentionally unused params (callbacks, route handlers)
- Replace remaining `any` with `unknown` + type guard for genuinely dynamic data
- Add `!` assertions only when TypeScript can't infer non-null from control flow (rare)

## Verification

```bash
tsc --noEmit     # Zero type errors
biome lint .     # Zero lint errors
pnpm build       # Full build passes
```

### CI enforcement

Add to pipeline to prevent regression:

```yaml
- run: tsc --noEmit
- run: biome ci .
```

`biome ci` is the CI-specific command — it checks format + lint without writing files,
and exits non-zero on any violation.

## Anti-patterns

- **Bulk `any` -> `Record<string, unknown>`**: Creates cascading errors, no type safety gain
- **`as any` to silence errors**: Hides real type mismatches
- **Double casts (`as unknown as T`)**: Acceptable only at ORM/serialization boundaries
- **`@ts-ignore`**: Use `@ts-expect-error` with a description instead; it auto-errors when the issue is fixed
- **Parallel bulk-fix agents**: Produces mechanical patches; audit and plan first instead
