---
layout: post
title: "From 2 Fields to 24: Scaling OpenAI Structured Outputs for Document Recognition"
subtitle: "How Zod schemas, dual extraction modes, and a single source of truth tamed our registration recognition service"
tags: [OpenAI, TypeScript, Zod, NestJS, structured-outputs, AI, backend]
comments: true
time: 5
---

We had a registration recognition service that worked. It took an image of a German vehicle registration certificate (*Zulassungsbescheinigung Teil I*), sent it to OpenAI's vision API, and came back with two fields: the VIN and a checksum. That was it. Two fields.

Then the product team asked: "Can we get the owner's name, address, the vehicle brand, fuel type, registration dates, inspection dates, the numberplate, HSN, TSN…?" — the full 24-field extraction. Oh, and some workflows only need 9 of those fields, so we'd like a lightweight mode too. And please don't break the existing API.

This is the story of how we scaled a toy extraction into a production-grade, dual-mode recognition pipeline — and why Zod became the linchpin of the entire design.

## The Challenge

The original service was straightforward: a prompt, an inline schema, a TypeScript interface, and a ViewModel class. Each of those four artifacts defined the shape of the data independently. When there were only two fields, the duplication was manageable. At 24 fields across two modes (full and THG-lightweight), it would have been a maintenance nightmare.

There was also a subtler problem. We were passing raw Mongoose documents into the prompt context. Subdocument internals — `$__`, `$isNew`, `_doc`, `$__parent` — were leaking into the serialized JSON, wasting tokens and polluting the LLM's context window. With the expanded field set consuming more output tokens, we couldn't afford to also waste input tokens on Mongoose metadata.

The real engineering challenge wasn't "call OpenAI with more fields." It was: **how do you define a complex, multi-mode extraction schema once and have it flow correctly through validation, type-checking, prompt engineering, and API serialization?**

## The Approach: Zod as the Single Source of Truth

We adopted a pattern already established in other parts of our codebase (PDF report extraction, MCP tools): **Zod schemas are the canonical definition, and everything else derives from them.**

Here's the core schema structure:

```typescript
// registration-recognition.zod.ts
import { registrationResults } from '../../report/zod/report.zod';

export const ThgRegistrationRecognitionSchema = registrationResults
  .pick({
    identificationnumber: true,
    numberplate: true,
    firstregistrationDay: true,
    firstregistrationMonth: true,
    firstregistrationYear: true,
    manufacturerNameCode: true,
    manufacturerTypeCode: true,
    fuelType: true,
    evbNumber: true,
  })
  .extend({
    checksum: z.string().nullable().describe('VIN check digit (position 9)'),
  });

export const FullRegistrationRecognitionSchema = registrationResults
  .extend({
    checksum: z.string().nullable().describe('VIN check digit (position 9)'),
  });

export type IThgRegistrationRecognitionResult =
  z.infer<typeof ThgRegistrationRecognitionSchema>;
export type IRegistrationRecognitionResult =
  z.infer<typeof FullRegistrationRecognitionSchema>;
```

A few things to notice:

1. **`report.zod.ts` is the single source of truth** for field names and base types. The registration recognition schemas compose from it rather than redefining fields. When a field name changes in the report schema, it changes everywhere.

2. **THG mode uses `.pick()`** to select exactly the 9 fields needed. Full mode gets everything. The `checksum` field is recognition-specific (not part of the report schema), so it's added via `.extend()`.

3. **Types are derived via `z.infer<>`**, not manually written interfaces. This eliminates an entire class of bugs where the interface says one thing and the validation says another.

### Describing Fields for the LLM

OpenAI's structured output feature works best when the schema includes descriptions. Zod's `.describe()` method is perfect for this:

```typescript
firstregistrationMonth: z.number()
  .nullable()
  .describe('Month of first registration (Feld I). Found in section I of the document.'),
initialRegistrationMonth: z.number()
  .nullable()
  .describe('Month of initial registration (Feld B). Found in section B of the document.'),
```

That `Feld I` / `Feld B` disambiguation was critical. German registration certificates have both a "first registration" date (when the vehicle was first registered anywhere) and an "initial registration" date (when it was registered to the current owner). Without explicit field-location hints, the LLM would frequently confuse them — returning the same date for both.

### Dual Mode in the Service

The service accepts an optional `mode` parameter:

```typescript
async recognizeRegistration(
  image: IBaseImage,
  mode: RegistrationRecognitionModeEnum = RegistrationRecognitionModeEnum.FULL,
) {
  const schema = mode === RegistrationRecognitionModeEnum.THG
    ? ThgRegistrationRecognitionSchema
    : FullRegistrationRecognitionSchema;

  const result = await this.openAiService.parseImage({
    image,
    schema,
    prompt: this.buildPrompt(mode),
  });

  return result;
}
```

THG mode sends a smaller schema to OpenAI, which means fewer output tokens and faster responses. In our measurements, THG mode runs roughly 40% faster and costs proportionally less — meaningful when you're processing thousands of registrations per month.

### Backward Compatibility

The existing API returned `vehicle_identification_number` as the field name. Our new schema uses `identificationnumber` (aligned with `report.zod.ts`). The ViewModel handles the mapping:

```typescript
export class OpenAiRegistrationRecognitionViewModel {
  vehicle_identification_number: string;

  constructor(result: IRegistrationRecognitionResult) {
    this.vehicle_identification_number = result.identificationnumber ?? '';
    // ... map remaining fields
  }
}
```

Internal naming follows the canonical schema; the API contract stays stable. No breaking changes for existing consumers.

## Lessons Learned

**Schema-first design pays compound interest.** When the schema is the source of truth, adding a field means changing one file. The type updates automatically, the validation updates automatically, and the LLM gets the `.describe()` context automatically. The alternative — updating an interface, a schema, a prompt, and a ViewModel independently — is where bugs hide.

**LLM prompt engineering is domain-specific in surprising ways.** The `Feld I` vs `Feld B` disambiguation was not something we anticipated. It only surfaced after testing with real German registration documents. If you're building structured extraction, budget time for iterating on field descriptions with real data — the schema structure is the easy part.

**Dual modes aren't just a cost optimization — they're an architectural signal.** Having `full` and `thg` modes forced us to think about which fields are truly required for each workflow. That clarity propagated into the frontend and queue processing: the image recognition task now passes the mode through, and downstream consumers only get the data they need.

**Clean your context.** Stripping Mongoose internals from the prompt context was a small change with outsized impact. Every irrelevant token in your prompt is money spent and accuracy lost. If you're serializing ORM objects into LLM prompts, audit what's actually going over the wire.

## Looking Forward

The 24-field extraction is live in production, processing queued images automatically via a cron job that polls every 5 seconds. The next step is expanding the same pattern to other image types — damage photos, license plates, cockpit images — each with their own Zod schemas composing from shared base definitions. The infrastructure is in place; it's now a matter of writing prompts and schemas, not plumbing.

If you're building structured extraction with OpenAI, I'd strongly encourage adopting Zod (or an equivalent in your language) as your schema layer. The upfront investment in "one schema to rule them all" pays for itself the moment you need to add a field, support a new mode, or debug why the LLM is returning the wrong date.
