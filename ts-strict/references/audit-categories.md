# Audit Categories

Common root causes of `any` and weak types in TypeScript codebases.

## 1. Untyped API Responses

External HTTP APIs returning JSON parsed as `any` or `unknown`.

**Symptoms**: `response.data` typed as `any`, `await res.json()` untyped, `Record<string, unknown>` with nested property access failures.

**Detection**: Search for `response.json()`, `axios.get`, `fetch(` without generic params.

## 2. Raw SQL / Untyped ORM Queries

`db.execute(sql\`...\`)` returns untyped rows. Also: `Partial<T>` return types that make non-null schema fields optional.

**Symptoms**: `result[0] as Record<string, unknown>`, `row.field` typed as `unknown`, `Partial<T>[]` where fields are known.

**Detection**: Search for `db.execute`, `sql\``, `.query(`, `Partial<` in return types.

### 2a. ORM Type Inference Bugs

Drizzle-specific patterns where the typed query builder collapses to `any` due to circular types or missing generic constraints — not raw SQL, but still produces `any`.

**Symptoms**: Self-referential FK infers `any`, generic query builder helper typed as `(query: any) => any`.

**Detection**: Search for `references((): any =>` (self-referential FK) and `applyFilters.*query: any` (generic query builders).

## 3. External Data Payloads

JWT payloads, webhook bodies, form data, WebSocket messages — any data crossing a trust boundary.

**Symptoms**: `payload as Record<string, unknown>`, `decoded.email` typed as `unknown`, property access on `unknown`.

**Detection**: Search for `jwtVerify`, `req.body`, webhook handlers, `JSON.parse`.

## 4. Event Handlers and Callbacks

Framework callbacks with implicit `any` params (React event handlers, Express middleware, etc.).

**Symptoms**: `(e: any) =>`, `(req: any, res: any)`, `(err: any)`.

**Detection**: Search for `: any)` pattern in function signatures.

## 5. Serialization Boundaries

JSON serialization/deserialization, localStorage, JSONB database columns, `structuredClone`.

**Symptoms**: `JSON.parse(...)` returning `any`, JSONB columns typed as `unknown`, state serialized to/from storage.

**Detection**: Search for `JSON.parse`, `jsonb`, `localStorage.getItem`.

## 6. Third-Party Library Types

Libraries with incomplete type definitions, or `@types/*` packages that use `any` in their signatures.

**Symptoms**: Library function returns `any`, callback params untyped, missing `@types/*` package.

**Detection**: Check `node_modules/@types/` for the library, search for `any` in `.d.ts` files.

## 7. Intentionally Unused Parameters

Route handlers (`_request`), destructured values (`const [_, setValue]`), callback signatures requiring specific arity.

**Symptoms**: `_` or `_name` prefixed variables flagged by `no-unused-vars`.

**Fix**: Configure rule, not code. Biome ignores `_`-prefixed variables by default. If not, prefix intentionally unused params with `_`.

## 8. Dead Code

Genuinely unused variables, imports, and functions left from refactoring.

**Symptoms**: Imports with no references, variables assigned but never read, functions never called.

**Fix**: Delete the dead code. Don't rename with `_` prefix — that hides the problem.

## 9. Catch Variables

`catch (e)` is `any` by default. With `useUnknownInCatchVariables` (included in `strict`), it becomes `unknown`.

**Symptoms**: `e.message` errors, `e.stack` access on `unknown`, bare `throw e` with no narrowing.

**Detection**: Search for `catch (`, check if `useUnknownInCatchVariables` is enabled.

## 10. Class Property Initialization

Uninitialized class properties flagged by `strictPropertyInitialization`.

**Symptoms**: `Property 'x' has no initializer and is not definitely assigned in the constructor.`

**Detection**: Search for class declarations, look for properties without initializers or constructor assignments. Common in DI frameworks (NestJS, Angular) where initialization happens outside the constructor.

## 11. Unchecked Index Access

With `noUncheckedIndexedAccess`, array index and object bracket access returns `T | undefined` instead of `T`.

**Symptoms**: `Object is possibly 'undefined'` on `arr[0]`, `obj[key]`, `record[dynamicKey]`.

**Detection**: Search for `[0]`, `[key]`, `[i]` patterns on typed arrays and records. High error count in codebases that assume array access always succeeds.
