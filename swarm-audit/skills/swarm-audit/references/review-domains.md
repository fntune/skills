# Review Domain Partitioning Strategies

## Principles

1. **Non-overlapping** — Each file belongs to exactly one domain. Prevents merge conflicts from concurrent agents.
2. **Balanced** — Roughly equal file count per domain (~20-50 files each).
3. **Cohesive** — Files in a domain share patterns, so the reviewer builds context efficiently.
4. **Independent** — Domains can be reviewed in parallel without cross-references.

---

## Next.js App Router (Recommended: 5 domains)

### Domain 1: Server Actions & API Routes
```
lib/**/actions.ts
lib/**/actions/*.ts
app/api/**/*.ts
```
**Focus:** Auth checks, tenant isolation, input validation, permissions.

### Domain 2: Dashboard Pages (non-settings)
```
app/dashboard/**/page.tsx          (excluding settings/)
app/dashboard/**/*-client.tsx      (excluding settings/)
```
**Focus:** Server-first pattern, requirePagePermission, data fetching.

### Domain 3: Settings Pages
```
app/dashboard/settings/**/page.tsx
app/dashboard/settings/**/*-client.tsx
```
**Focus:** Permission gates, form handling, API integration.

### Domain 4: Shared Components
```
components/**/*.tsx                (excluding ui/ primitives)
```
**Focus:** React patterns, type safety, accessibility, dead code.

### Domain 5: Library Code
```
lib/**/*.ts                        (excluding actions files from Domain 1)
```
**Focus:** Type safety, error handling, caching, performance.

---

## Alternative: By Concern (4 domains)

Use when reviewing a specific concern across the entire codebase.

### Domain 1: Security
All files containing auth, permissions, tenant, session patterns.

### Domain 2: Type Safety
All files with `any`, `as any`, `z.any()`, `Record<string, any>`.

### Domain 3: React Patterns
All `.tsx` files — useEffect, useMemo, Suspense, state management.

### Domain 4: Code Quality
All files — dead code, duplication, performance, error handling.

---

## Python (Flask/Django) — 5 domains

### Domain 1: Routes & Views
```
app/routes/**/*.py
app/views/**/*.py
```

### Domain 2: Models & Schemas
```
app/models/**/*.py
app/schemas/**/*.py
```

### Domain 3: Services & Business Logic
```
app/services/**/*.py
app/utils/**/*.py
```

### Domain 4: Tests
```
tests/**/*.py
```

### Domain 5: Config & Infrastructure
```
app/config/**/*.py
app/middleware/**/*.py
migrations/**/*.py
```

---

## Sizing Guidelines

| Codebase Size | Domains | Reviewers | Workers |
|---------------|---------|-----------|---------|
| Small (<100 files) | 3 | 3 | 2-3 |
| Medium (100-500 files) | 5 | 5 | 3-5 |
| Large (500+ files) | 5-7 | 5-7 | 5-7 |

**Worker count rule:** Start with same count as reviewers. Scale down if tasks are small; spawn new workers for large tasks (>15 files).

---

## File Count Discovery

Estimate domain sizes before spawning:

```bash
# Count files per domain
find app/dashboard/settings -name "*.tsx" | wc -l
find components -name "*.tsx" -not -path "*/ui/*" | wc -l
find lib -name "*.ts" | wc -l
```

Rebalance if any domain has >3x the files of another. Split large domains or merge small ones.
