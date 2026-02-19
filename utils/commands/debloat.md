---
description: Debloat code and remove AI slop
---

# Debloat Codebase (Py / TS)

Compact rules for Python and TypeScript/Next.js. Prefer high-signal, low-noise changes.

## Core Actions (Both)
- Move imports to top of file
- Remove superfluous comments (keep why/how)
- Remove commented-out code
- Remove AI slop: extra defensive checks/try-catch, off-style patterns
- Remove useless error wrappers; keep context/logging/fallbacks
- Avoid `any` casts; fix types properly
- Fail fast with clear errors

## Python-Specific
### Patterns
- Defensive import → explicit top-level import  
  `try: from x import y ... except ImportError: y=None` → `from x import y`
- Generic error wrapping → remove  
  `except Exception as e: raise RuntimeError(...e)` → delete
- Decorative emojis → remove from code/docs

### Import Order (PEP 8)
1. stdlib
2. third-party
3. local (relative last)
Alphabetize within groups, blank line between groups.

## TypeScript/Next.js-Specific
### Patterns
- `console.(log|error|warn)` → structured logger in production  
  (allow console in dev tools/scripts)
- Generic catch wrapping → remove  
  `catch (e) { throw new Error(...) }` or `throw e`
- Remove stale TODO/FIXME; keep meaningful ones
- Avoid `as any`; use `unknown` or proper types
- `use client` only when interactivity is needed

### Import Order
1. external
2. internal absolute (`@/`)
3. types (inline or own group)
4. relative
Alphabetize within groups, blank line between groups.

## Examples (Minimal)
### Console → Logger (TS)
```ts
logger.info('Starting execution', { id });
```

### Defensive Import → Top-Level (Py)
```py
from data.processor import DataProcessor
```
