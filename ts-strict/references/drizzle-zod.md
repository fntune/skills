# Drizzle + Zod v4: Full-Stack Type Safety

Single source of truth: define the DB schema once in Drizzle, derive Zod schemas from it,
infer TypeScript types from Zod, propagate those types through the entire stack.

```
DB Schema (pgTable)
  → createSelectSchema / createInsertSchema / createUpdateSchema   (drizzle-orm/zod)
    → z.infer<typeof schema>                                       (TypeScript types)
      → API contracts (tRPC / server actions / REST)
        → frontend forms, state, fetchers                          (same types, no duplication)
```

---

## Setup: drizzle-orm/zod with Zod v4

`drizzle-zod` (separate package) is deprecated — use the native integration.

Create a shared factory module so every schema file uses the same Zod instance:

```typescript
// db/schema/_factory.ts
import { createSchemaFactory } from "drizzle-orm/zod";
import { z } from "zod";  // zod v4

export const { createSelectSchema, createInsertSchema, createUpdateSchema } =
  createSchemaFactory({ zodInstance: z });
```

Without `createSchemaFactory`, the built-in helpers use the bundled Zod version which
may not match your project's version. Always use `createSchemaFactory` explicitly.

---

## Core Pattern: Schema Co-location

Define Zod schemas in the same file as the Drizzle table. Export both the schema and
the inferred types — these become the contract consumed everywhere else.

```typescript
// db/schema/users.ts
import { pgTable, text, integer, timestamp } from "drizzle-orm/pg-core";
import { createSelectSchema, createInsertSchema, createUpdateSchema } from "./_factory";
import { z } from "zod";

// 1. DB table definition
export const users = pgTable("users", {
  id:        integer().generatedAlwaysAsIdentity().primaryKey(),
  name:      text().notNull(),
  email:     text().notNull().unique(),
  role:      text().$type<"admin" | "user">().notNull().default("user"),
  createdAt: timestamp().defaultNow().notNull(),
});

// 2. Zod schemas derived from table — runtime + compile-time validation
//    Use overrides (z.xxx()) not refinement callbacks for v4 format validators
export const userSelectSchema = createSelectSchema(users, {
  email: z.email(),                 // override: v4 top-level validator
  name:  (s) => s.max(100),        // refine: extends the generated ZodString
});

export const userInsertSchema = createInsertSchema(users, {
  email: z.email(),
  name:  (s) => s.min(1).max(100),
  role:  z.enum(["admin", "user"]),
});

export const userUpdateSchema = createUpdateSchema(users, {
  email: z.email(),
  name:  (s) => s.min(1).max(100),
});

// 3. TypeScript types inferred from Zod — single source of truth
export type User       = z.infer<typeof userSelectSchema>;
export type NewUser    = z.infer<typeof userInsertSchema>;
export type UserUpdate = z.infer<typeof userUpdateSchema>;

// 4. Raw DB types (no Zod overhead) — use when you trust the DB
export type UserRow    = typeof users.$inferSelect;
export type NewUserRow = typeof users.$inferInsert;
```

`createInsertSchema` excludes generated/identity columns (`id`) and makes defaulted
columns optional. `createUpdateSchema` makes all columns optional.

---

## JSONB Columns

`.$type<T>()` provides TypeScript inference only — no runtime validation. For runtime
safety, define the Zod schema for the JSONB content and override the column in
`createInsertSchema`.

```typescript
// db/schema/orders.ts
import { pgTable, integer, jsonb } from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "./_factory";
import { z } from "zod";

// Define Zod schema for the JSONB content first
export const orderMetadataSchema = z.object({
  source:   z.enum(["web", "api", "mobile"]),
  campaign: z.string().optional(),
  tags:     z.array(z.string()).default([]),
});
export type OrderMetadata = z.infer<typeof orderMetadataSchema>;

export const orderItemSchema = z.object({
  productId: z.string(),
  quantity:  z.number().int().positive(),
  unitPrice: z.number().positive(),
});
export type OrderItem = z.infer<typeof orderItemSchema>;

export const orders = pgTable("orders", {
  id:       integer().generatedAlwaysAsIdentity().primaryKey(),
  userId:   integer().notNull(),
  // $type<T>() = compile-time TypeScript inference only
  metadata: jsonb().$type<OrderMetadata>().notNull(),
  items:    jsonb().$type<OrderItem[]>().notNull(),
});

// Override JSONB columns with Zod schemas for runtime validation
// This is the current workaround for the $type redundancy
export const orderInsertSchema = createInsertSchema(orders, {
  metadata: orderMetadataSchema,          // runtime validates structure
  items:    z.array(orderItemSchema).min(1),
});

export const orderSelectSchema = createSelectSchema(orders, {
  metadata: orderMetadataSchema,
  items:    z.array(orderItemSchema),
});

export type Order    = z.infer<typeof orderSelectSchema>;
export type NewOrder = z.infer<typeof orderInsertSchema>;
```

**Known limitation**: nested JSONB arrays/objects beyond 1 level deep may infer as
`unknown` in some drizzle-orm/zod versions — test your version and add explicit
overrides for any nested structures.

**Coming soon**: `.$validator(schema)` API ([drizzle#5167](https://github.com/drizzle-team/drizzle-orm/issues/5167))
will attach the Zod schema to the column directly, eliminating the redundant override.

---

## API Layer: Validate at the Boundary

Use the generated schemas to validate at every trust boundary — API inputs, DB responses,
external data. Do not validate in the middle of the call chain.

When the action is the trust boundary (server actions, REST handlers), parse `unknown` input:

```typescript
// lib/users/actions.ts (Next.js server action — receives unvalidated input)
import {
  users,
  userInsertSchema, userUpdateSchema,
  type User,
} from "@/db/schema/users";
import { db } from "@/db";
import { eq } from "drizzle-orm";

export async function createUser(raw: unknown): Promise<User> {
  const data = userInsertSchema.parse(raw); // validate input at boundary

  const [row] = await db.insert(users).values(data).returning();
  // Cast bridges Drizzle's inferred column types with Zod-refined types.
  // Safe because Zod overrides only add validation constraints, not structural differences.
  return row as User;
}

export async function updateUser(id: number, raw: unknown): Promise<User> {
  const data = userUpdateSchema.parse(raw);

  const [row] = await db
    .update(users)
    .set(data)
    .where(eq(users.id, id))
    .returning();

  if (!row) throw new Error(`user ${id} not found`);
  return row as User;
}
```

When a framework validates upstream (tRPC `.input()`, Zod-validated form libraries), accept
the typed result directly — don't re-parse. See the [tRPC section](#trpc-schema-as-procedure-contract)
for this pattern.

Use `selectSchema.parse()` on DB output only when the response crosses a trust boundary
(e.g., API returning to an external consumer where you want to strip extra fields or
catch schema drift). For internal callers that trust the DB, the Drizzle return type suffices.

For non-throwing validation (form handling, graceful errors):

```typescript
const result = userInsertSchema.safeParse(raw);
if (!result.success) {
  return { error: result.error.issues };  // .issues in Zod v4 (not .errors)
}
const data = result.data; // NewUser
```

---

## tRPC: Schema as Procedure Contract

When tRPC validates `.input()`, the mutation handler receives the already-typed result.
The action functions should accept the typed input directly — not `unknown`.

```typescript
// lib/users/actions.ts — typed signatures (tRPC already validated)
import { users, type User, type NewUser, type UserUpdate } from "@/db/schema/users";
import { db } from "@/db";
import { eq } from "drizzle-orm";

export async function createUser(data: NewUser): Promise<User> {
  const [row] = await db.insert(users).values(data).returning();
  return row as User;
}

export async function updateUser(id: number, data: UserUpdate): Promise<User> {
  const [row] = await db.update(users).set(data).where(eq(users.id, id)).returning();
  if (!row) throw new Error(`user ${id} not found`);
  return row as User;
}
```

```typescript
// server/routers/users.ts
import { z } from "zod";
import { publicProcedure, router } from "../trpc";
import { userInsertSchema, userUpdateSchema, userSelectSchema } from "@/db/schema/users";
import { createUser, updateUser } from "@/lib/users/actions";

export const usersRouter = router({
  create: publicProcedure
    .input(userInsertSchema)     // Drizzle-derived Zod schema as input contract
    .output(userSelectSchema)    // Drizzle-derived Zod schema as output contract
    .mutation(({ input }) => createUser(input)),  // input is NewUser, not unknown

  update: publicProcedure
    .input(z.object({ id: z.number(), data: userUpdateSchema }))
    .output(userSelectSchema)
    .mutation(({ input }) => updateUser(input.id, input.data)),
});

// Compose into app router and export type for client
const appRouter = router({ users: usersRouter });
export type AppRouter = typeof appRouter;
```

Frontend gets full types from `AppRouter` with no schema duplication:

```typescript
// components/CreateUserForm.tsx
import { type NewUser } from "@/db/schema/users";
import { trpc } from "@/lib/trpc";

function CreateUserForm() {
  const mutation = trpc.users.create.useMutation();

  function handleSubmit(data: NewUser) {  // type comes from the shared schema
    mutation.mutate(data);
  }
}
```

---

## Schema Refinements for Cross-Field Validation

`createInsertSchema` handles per-field validation. For cross-field rules (e.g. end > start),
chain `.refine()` on the result:

```typescript
export const eventInsertSchema = createInsertSchema(events).refine(
  (data) => data.endAt.getTime() > data.startAt.getTime(),
  { message: "endAt must be after startAt", path: ["endAt"] },
);
```

---

## Enum Columns

```typescript
import { pgEnum, pgTable } from "drizzle-orm/pg-core";
import { createSelectSchema } from "./_factory";
import { z } from "zod";

export const roleEnum = pgEnum("role", ["admin", "user", "viewer"]);
export const roleSchema = createSelectSchema(roleEnum);  // "admin" | "user" | "viewer"
export type Role = z.infer<typeof roleSchema>;

// Use directly in table + no duplication
export const users = pgTable("users", {
  role: roleEnum().notNull().default("user"),
});
```

---

## Exporting Strategy

Centralize schema exports so the rest of the codebase imports from one place:

```typescript
// db/schema/index.ts
export * from "./users";
export * from "./orders";
export * from "./products";
// Re-exports: tables, Zod schemas, inferred types — one import path for everything
```

Consumers import types and schemas from `@/db/schema`, not from individual files.
This keeps the import graph shallow and the refactoring surface small.
