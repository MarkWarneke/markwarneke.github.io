---
layout: post
title: "How a Missing Zod Enum Value Silently Broke Every AI Agent Tool"
subtitle: "When output validation schemas become stricter than your database, everything grinds to a halt"
tags: [NestJS, Zod, TypeScript, MCP, Schema-Validation, DevOps, AI-Agents]
comments: true
time: 5
---

There's a category of bug that doesn't throw an error in your logs, doesn't trigger an alert, and doesn't fail a single test — yet silently renders an entire feature unusable. We hit one recently, and it came down to a single Zod enum missing a handful of string values.

If you're building APIs where AI agents consume your tools via something like the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), this one's worth internalizing.

## The Setup: MCP Tools with Zod Output Schemas

We maintain a NestJS backend that exposes a growing set of MCP tools — structured functions that AI agents call to interact with our domain: fetching repair estimates, searching documents, managing clearances, and so on. Each tool defines both an **input schema** (what the agent sends) and an **output schema** (what we guarantee comes back). Both are defined in Zod.

The output schemas exist for a good reason: they act as a contract. If our API returns data that doesn't match the schema, Zod throws a validation error and the tool call fails. This protects agents from receiving unexpected shapes and protects us from leaking internal data structures.

Most of our domain objects carry a `refs` array — references linking one resource to another. A repair estimate might reference a report, a person, and a few images. Each ref has a `refType` string indicating the resource type. Our Zod output schema for refs looked like this:

```typescript
export const McpRefTypeSchema = z.enum([
  'report',
  'repair_estimate',
  'document',
  'clearance',
  'ticket',
  'contract',
  'message',
]);
```

Seven types. Seemed comprehensive enough when it was written.

## The Problem: A Schema That Was Right — Until It Wasn't

Over several weeks, we'd been building out new domain areas: shared content links, attachment requests, image management, and more. Each new feature introduced new reference types into the database. A shared content link referencing a person? That's `refType: 'person'`. An invoice clearance referencing an image? `refType: 'image'`.

Here's the thing: the **database** was happy to store these. The **service layer** was happy to return them. The **Mongoose schemas** had no enum constraint on `refType`. But the **Zod output schema** did.

The moment any MCP tool returned a response containing a ref with `refType: 'person'` or `refType: 'shared_content'`, Zod's `z.enum()` validation rejected the entire response. Not just the offending ref — the *entire tool call*. The agent received an error, retried, got the same error, and gave up.

Every tool that returned `refs` in its response was broken: `get_repair_estimate`, `find_repair_estimates`, `get_document`, `find_documents` — all of them. And because the validation error happened at the output serialization layer, our application logs showed nothing unusual. The database queries succeeded. The service methods returned data. The error only manifested in the MCP transport layer, which at the time had limited observability.

## The Fix (and the Refactoring It Triggered)

The immediate fix was straightforward — add the missing types:

```typescript
export const McpRefTypeSchema = z.enum([
  'report',
  'repair_estimate',
  'document',
  'clearance',
  'ticket',
  'contract',
  'message',
  // These were missing:
  'shared_content',
  'person',
  'vehicle',
  'call',
  'image',
  'invoice',
  'clearance_approval',
  'attachment_request',
]).min(1); // Also reject empty strings
```

But patching the enum wasn't enough. This bug was a symptom of a deeper problem: **our schemas were scattered, duplicated, and had no single source of truth**.

The `McpRefTypeSchema` was defined in one file. The `ResourceEnum` used by our authorization layer lived in another. The Mongoose schema's `refType` field accepted any string. Three representations of the same concept, none aware of the others.

So we undertook a broader refactoring. We created **canonical Zod schemas** for 12 core domains — ticket, person, vehicle, company, repair estimate, contract, message, shared content, and more. Each canonical schema derives directly from the Mongoose schema and serves as the single source of truth. DTOs and view models now compose from these canonical schemas rather than defining their own inline shapes.

We also dropped the `mcp-` prefix from shared schemas. Files like `mcp-reference.zod.ts` became `reference.zod.ts`, and symbols like `McpReferenceSchema` became `ReferenceSchema`. These schemas aren't MCP-specific — they're domain primitives used across seven or more modules. The naming was leaking implementation context into shared infrastructure.

```
# Before
lib/zod/mcp-reference.zod.ts    → McpReferenceSchema
lib/zod/mcp-line-item.zod.ts    → McpLineItemSchema
repair-estimate.mcp-dto.zod.ts  → McpRepairEstimateInputSchema

# After
lib/zod/reference.zod.ts        → ReferenceSchema
lib/zod/line-item.zod.ts        → LineItemSchema
repair-estimate.dto.zod.ts      → RepairEstimateInputSchema
```

We also consolidated duplicated reference schemas. Four different domain files had been copy-pasting the same reference shape locally instead of importing from the shared `reference.zod.ts`. One `ReferenceSchema`, imported everywhere.

## Lessons Learned

**Output schemas are a double-edged sword.** They're valuable for guaranteeing contract compliance, but they introduce a failure mode that input-only validation doesn't have: your own data can violate your own schema. When your database is more permissive than your output serialization layer, you're writing a time bomb. Every new feature that introduces a new enum value, a new nullable field, or a new resource type is a potential breakage point.

**Enums need a canonical source.** If the same concept (resource types, status codes, severity levels) appears in more than one place, it *will* drift. We replaced inline `z.enum(['INFO', 'WARNING', 'VIOLATION'])` calls with `z.nativeEnum(ContractComplianceFindingSeverityEnum)` for the same reason. One definition, referenced everywhere.

**MCP output observability matters.** We caught this because agents started failing, not because our monitoring flagged it. If you're building tool-use APIs for AI agents, instrument your output validation layer. Log schema validation failures with the tool name, the failing path, and the unexpected value. We would have found this in minutes instead of after user reports.

**Name things for what they are, not where they started.** The `mcp-` prefix made sense when these schemas were a small experiment. By the time they were shared across a dozen modules, the prefix was actively misleading. Rename early; the diff only gets worse.

## Looking Forward

We're now evaluating whether the `refType` enum should be auto-generated from our `ResourceEnum` at build time, ensuring the output schema can never fall behind. We're also looking at adding a CI check that validates sample documents from each domain against their canonical Zod schema — a kind of schema integration test that catches drift before it reaches production.

If you're building structured tool APIs — whether for MCP, function calling, or any agent framework — take a hard look at your output schemas. They're protecting your consumers, but they might also be the thing silently breaking them.
