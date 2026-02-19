# Fix Patterns

Concrete patterns for resolving each audit category at the source.

## API Response Interfaces

Define an interface matching the actual response shape. Place it next to the API client function.

```typescript
// Bad: caller does (await res.json()) as any
export async function getUser(id: string) {
  const res = await fetch(`/api/users/${id}`);
  return await res.json(); // returns unknown/any
}

// Good: typed at the source
interface UserResponse {
  id: string;
  name: string;
  email: string;
  role: "admin" | "user";
}

export async function getUser(id: string): Promise<UserResponse> {
  const res = await fetch(`/api/users/${id}`);
  return await res.json() as UserResponse; // single cast at API boundary
}
```

Build interface from: API docs, runtime response samples (`console.log`), or actual usage sites (what fields are accessed downstream).

For stronger runtime guarantees, use Zod schemas instead of manual interfaces — see [Zod Boundary Validation](#zod-boundary-validation) below.

## ORM Typed Queries

### Drizzle: Replace `db.execute(sql)` with `db.select()`

```typescript
// Bad: raw SQL returns untyped rows
const rows = await db.execute(sql`SELECT name, email FROM users WHERE active = true`);
const name = (rows[0] as Record<string, unknown>).name; // unknown

// Good: typed select
const rows = await db
  .select({ name: users.name, email: users.email })
  .from(users)
  .where(eq(users.isActive, true));
// rows[0].name is string, rows[0].email is string | null (from schema)
```

### Fix `Partial<T>` return types

```typescript
// Bad: Partial makes everything optional, even notNull() columns
async function getCategories(): Promise<Partial<Category>[]> { ... }
// cat.name is string | undefined even though schema says notNull()

// Good: Pick preserves nullability from schema
async function getCategories(): Promise<Pick<Category, 'name' | 'externalId' | 'dept'>[]> { ... }
// cat.name is string (notNull preserved)
```

### Conditional `.where()` without `as any`

```typescript
// Bad: Drizzle type doesn't chain .where() after .innerJoin()
let qb = db.select({...}).from(t1).innerJoin(t2, eq(t1.id, t2.fk));
if (conds.length) qb = (qb as any).where(and(...conds));

// Good: inline with undefined fallback
const rows = await db
  .select({...})
  .from(t1)
  .innerJoin(t2, eq(t1.id, t2.fk))
  .where(conds.length > 0 ? and(...conds) : undefined)
  .orderBy(t1.createdAt);
```

### Self-referential foreign keys

Drizzle can't resolve circular types when a column references its own table (or two tables reference each other), causing the inferred type to collapse to `any`. Fix: annotate the callback return type with `AnyPgColumn`.

```typescript
import { AnyPgColumn } from "drizzle-orm/pg-core";

// Bad: type collapses to any
parentId: uuid("parent_id").references(() => nodes.id),

// Good: explicit return type breaks the circular inference
parentId: uuid("parent_id").references((): AnyPgColumn => nodes.id),
```

Alternative — standalone `foreignKey` builder avoids the circular reference entirely:

```typescript
import { foreignKey } from "drizzle-orm/pg-core";

export const nodes = pgTable(
  "nodes",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    parentId: uuid("parent_id"),
  },
  (self) => [
    foreignKey({ columns: [self.parentId], foreignColumns: [self.id] }),
  ],
);
```

### Generic query builder in base repositories

Drizzle query builders grow their type with each chained method, making them hard to pass to generic functions. The documented solution is `.$dynamic()` + dialect-specific generic types ([Drizzle docs: Dynamic query building](https://orm.drizzle.team/docs/dynamic-query-building)).

```typescript
import { PgSelect } from "drizzle-orm/pg-core";

// Bad: loses all type information
protected applyFilters(query: any, filters: WorkflowFilters): any { ... }

// Good: T extends PgSelect preserves full chain type
protected applyFilters<T extends PgSelect>(qb: T, filters: WorkflowFilters): T {
  let q = qb;
  if (filters.name) q = q.where(eq(this.table.name, filters.name)) as T;
  if (filters.status) q = q.where(eq(this.table.status, filters.status)) as T;
  return q;
}

// Call site: opt in to dynamic mode before passing to the helper
const rows = await this.applyFilters(
  db.select().from(this.table).$dynamic(),
  filters,
);
```

Available dialect types: `PgSelect` / `MySqlSelect` / `SQLiteSelect` (and `...QueryBuilder` variants for standalone query builder instances).

## External Data Boundary Validation

Validate with `typeof` to narrow types. This is correct at trust boundaries (JWT, webhooks, user input).

```typescript
// Bad: blind cast
const decoded = payload as Record<string, unknown>;
if (!decoded.email) return null;
decoded.email.endsWith("@co.com"); // Error: unknown has no .endsWith

// Good: typeof narrows the type
const decoded = payload as Record<string, unknown>;
if (typeof decoded.email !== "string") return null;
// decoded.email is now string
if (!decoded.email.endsWith("@co.com")) return null;
```

Extract validated fields into typed locals for cleaner downstream code:

```typescript
const email = decoded.email; // string (narrowed above)
const name = typeof decoded.name === "string" ? decoded.name : undefined;
const role = typeof decoded.role === "string" ? decoded.role : undefined;
```

## Callback and Event Handler Typing

Type the callback signature at its definition site so callers get inference automatically.

```typescript
// Bad: implicit any params
app.use((req: any, res: any, next: any) => { ... });

// Good: Express types
import type { Request, Response, NextFunction } from "express";
app.use((req: Request, res: Response, next: NextFunction) => { ... });
```

For custom callbacks, define the signature as a named type:

```typescript
// Bad: inline any
function onMessage(handler: (msg: any) => void) { ... }

// Good: named callback type
type MessageHandler = (msg: ParsedMessage) => void;
function onMessage(handler: MessageHandler) { ... }
```

Generic callbacks that wrap framework types:

```typescript
// Bad: loses type info
type Middleware = (ctx: any) => any;

// Good: generic preserves context type
type Middleware<TCtx> = (ctx: TCtx) => TCtx | Promise<TCtx>;
```

## Third-Party Library Types

When a library's types are incomplete or use `any`:

**1. Check for `@types/*` package:**
```bash
pnpm add -D @types/library-name
```

**2. Augment incomplete types with declaration merging:**
```typescript
// types/library-name.d.ts
declare module "library-name" {
  export function process(input: string): ProcessResult;  // was: any
}
```

**3. Wrap the untyped call at one place:**
```typescript
// lib/library-wrapper.ts — single typed boundary
import { riskyCall } from "library-name";

interface TypedResult { id: string; status: "ok" | "error" }

export function typedCall(input: string): TypedResult {
  return riskyCall(input) as TypedResult;  // single cast, not scattered
}
```

The wrapper concentrates the `as` cast in one file. Downstream code imports the typed wrapper,
not the raw library. When the library ships better types, you fix one file.

## Return Type Tightening

When a function returns a union that's too wide for one specific caller:

```typescript
// State has 5 possible decisions but makeHrDecision only accepts 3
// Bad: pass the wide type and cast
makeHrDecision(state.currentDecision as "approved" | "rejected" | "deferred");

// Good: narrow with a type guard before the call
const d = state.currentDecision;
if (d !== "approved" && d !== "rejected" && d !== "deferred") {
  return "Invalid state.";
}
makeHrDecision(d); // TypeScript knows d is one of the 3
```

## `satisfies` for Config and Literal Objects

`satisfies` validates a value against a type without widening the inferred type. Use it instead of `: Type` annotations when you need shape-checking but still want autocomplete on the specific literal values, and instead of `as Type` when you don't want to bypass the type system.

```typescript
// Bad: type annotation widens — route names become string, not literal
const routes: Record<string, string> = {
  home: "/",
  users: "/users",
};
routes.unknown; // no error — widened to Record<string, string>

// Bad: as assertion — bypasses type checks entirely
const config = { host: "localhost", port: "not-a-number" } as ServerConfig;

// Good: satisfies — validates shape, preserves literal types
const routes = {
  home: "/",
  users: "/users",
} satisfies Record<string, string>;
routes.unknown; // Error: 'unknown' does not exist

// Good: combine annotation + satisfies for complex config
const serverConfig = {
  host: "localhost",
  port: 3000,
  tls: false,
} satisfies ServerConfig;
// serverConfig.port is 3000 (literal), not number
```

Combine with `as const` for readonly literal types with shape validation:

```typescript
const ERROR_CODES = {
  NOT_FOUND: 404,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
} as const satisfies Record<string, number>;
// ERROR_CODES.NOT_FOUND is 404 (literal), not number; object is readonly
```

`satisfies` is especially useful for:
- Route/URL maps — validates keys exist without losing literal types
- Feature flag objects — enforces shape while keeping values narrowed
- Enum-to-label mappings — catches missing cases at compile time
- `WorkflowError` / result objects — ensures every field is present without widening

## Discriminated Union Exhaustiveness

When switching on a discriminated union, add an `assertExhaustive` call in the `default` branch. TypeScript narrows the discriminant to `never` when all cases are handled — the assertion fails to compile if you add a new union member without updating the switch.

```typescript
function assertExhaustive(value: never, message?: string): never {
  throw new Error(message ?? `Unhandled case: ${JSON.stringify(value)}`);
}

type WorkflowEvent =
  | { type: "started"; workflowId: string }
  | { type: "completed"; result: unknown }
  | { type: "failed"; error: string };

function handleEvent(event: WorkflowEvent): void {
  switch (event.type) {
    case "started":
      log.info("workflow started", { id: event.workflowId });
      break;
    case "completed":
      processResult(event.result);
      break;
    case "failed":
      log.error("workflow failed", { error: event.error });
      break;
    default:
      // Adding a new union member without handling it here is a compile error
      assertExhaustive(event);
  }
}
```

Define `assertExhaustive` once in a shared utils file. The `never` parameter is both the compile-time guard and the runtime guard — if somehow reached at runtime, it throws with the unhandled value serialized.

## Null vs Undefined Mismatches

Common at ORM boundaries where schema uses `null` but application state uses `undefined`.

```typescript
// Schema: subcategory varchar nullable -> string | null
// State: subcategory?: string           -> string | undefined

// Convert at the assignment point
state.subcategory = dbRow.subcategory ?? undefined;
```

Acceptable at assignment boundaries. Not a bandaid — it's a real semantic conversion between two null representations.

## JSONB Serialization Boundaries

Drizzle JSONB columns expect `Record<string, unknown>` but application types don't have index signatures.

For Drizzle projects using Zod, the better approach is to define Zod schemas for JSONB content
and override the column in `createInsertSchema` — see [drizzle-zod.md](drizzle-zod.md#jsonb-columns).

When Zod overrides aren't available, the double-cast at the serialization boundary is acceptable:

```typescript
// Acceptable double-cast at ORM serialization boundary
await db.insert(table).values({
  state: appState as unknown as Record<string, unknown>,
});
```

This is the one place double-casts are acceptable. The JSONB column genuinely accepts any JSON-serializable object; TypeScript just can't express that constraint.

For general serialization boundaries (`JSON.parse`, `localStorage.getItem`, `structuredClone`),
validate the result with Zod — see [Zod Boundary Validation](#zod-boundary-validation).

## Array vs Object in Generic Code

When a function handles both arrays and objects:

```typescript
// Bad: arrays don't satisfy Record<string, unknown>
const result: Record<string, unknown> = Array.isArray(obj) ? [] : {};

// Good: split the branches
if (Array.isArray(obj)) {
  return obj.map(item => process(item));
}
const result: Record<string, unknown> = {};
for (const [key, value] of Object.entries(obj)) {
  result[key] = process(value);
}
```

## Zod Boundary Validation

For trust boundaries (API responses, JWT payloads, webhooks, env vars), use Zod instead of hand-rolled `typeof` guards. Define the schema once; derive the TypeScript type from it.

> **Zod v4 note**: `z.string().email()` / `.uuid()` / `.url()` are deprecated — use top-level `z.email()`, `z.uuid()`, `z.url()` instead. `z.record()` now requires two args: `z.record(keySchema, valueSchema)`. Error access is `err.issues` (not `.errors`). See [Zod v4 changelog](https://zod.dev/v4/changelog).

```typescript
import { z } from "zod";

// v4 syntax
const UserResponse = z.object({
  id: z.string(),
  name: z.string(),
  email: z.email(),                    // top-level, not z.string().email()
  role: z.enum(["admin", "user"]),
});

type UserResponse = z.infer<typeof UserResponse>;

// At the API boundary — validates and narrows in one step
export async function getUser(id: string): Promise<UserResponse> {
  const res = await fetch(`/api/users/${id}`);
  return UserResponse.parse(await res.json()); // throws ZodError on invalid shape
}
```

For non-throwing validation, use `.safeParse()`:

```typescript
const result = UserResponse.safeParse(payload);
if (!result.success) {
  log.warn("invalid payload", { issues: result.error.issues }); // .issues in v4
  return null;
}
// result.data is UserResponse
```

Env var validation at startup:

```typescript
const Env = z.object({
  DATABASE_URL: z.string().min(1),  // z.url() may reject valid connection strings
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(["development", "production", "test"]),
});

export const env = Env.parse(process.env); // fail fast on missing/invalid vars
```

Keep the existing `typeof` narrowing patterns for projects not using Zod, or for one-off checks where adding a schema is overkill.

## Catch Variable Handling

With `useUnknownInCatchVariables: true` (included in `strict`), catch variables are `unknown` instead of `any`.

```typescript
// Bad: assumes error is Error
try { ... } catch (e) {
  console.error(e.message); // Property 'message' does not exist on type 'unknown'
}

// Good: narrow with instanceof
try { ... } catch (e) {
  if (e instanceof Error) {
    console.error(e.message);
  } else {
    console.error("unexpected error", e);
  }
}
```

Reusable helper for codebases with many catch blocks:

```typescript
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

// Usage
try { ... } catch (e) {
  log.error(getErrorMessage(e));
}
```

## Class Property Initialization

`strictPropertyInitialization` requires class properties to be initialized at declaration or in the constructor.

### Initialize at declaration

```typescript
class Cache {
  private items: Map<string, unknown> = new Map();
  private ttl: number = 300;
}
```

### Initialize in constructor

```typescript
class DbClient {
  private pool: Pool;

  constructor(config: PoolConfig) {
    this.pool = new Pool(config);
  }
}
```

### Definite assignment assertion (DI only)

Use `!` only when a framework handles initialization outside the constructor (NestJS, Angular, TypeORM):

```typescript
class UserService {
  @Inject(DbClient)
  private db!: DbClient; // framework guarantees assignment before use
}
```

Never use `!` to silence the error when you control the initialization — fix the constructor instead.

## `noUncheckedIndexedAccess` Patterns

With this flag, `arr[0]` returns `T | undefined` and `obj[key]` returns `V | undefined`. This catches real bugs (empty arrays, missing keys) but produces many errors in existing code.

### Optional chaining after index

```typescript
// Bad: assumes array is non-empty
const firstName = users[0].name;

// Good: safe access
const firstName = users[0]?.name;
```

### Guard before access

```typescript
const first = items[0];
if (first === undefined) {
  throw new Error("expected at least one item");
}
// first is T (narrowed)
```

### Prefer `Map` for dynamic keys

```typescript
// Bad: Record index returns T | undefined, needs checks everywhere
const cache: Record<string, CacheEntry> = {};
const entry = cache[key]; // CacheEntry | undefined

// Good: Map.get() already returns T | undefined, same behavior but idiomatic
const cache = new Map<string, CacheEntry>();
const entry = cache.get(key); // CacheEntry | undefined
```

### Destructuring with assertion

```typescript
// When you've already validated length
if (parts.length !== 3) throw new Error("expected 3 parts");
const [a, b, c] = parts as [string, string, string];
```

