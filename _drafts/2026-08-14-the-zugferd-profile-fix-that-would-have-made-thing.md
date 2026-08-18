---
layout: post
title: "The ZUGFeRD Profile Fix That Would Have Made Things Worse"
subtitle: "Why fixing one hardcoded value in a hybrid PDF required changing two things at once"
tags: [e-invoice, ZUGFeRD, XRechnung, NestJS, PDF, TypeScript, compliance]
comments: true
time: 5
---

Every so often, a bug looks like a one-line fix and turns out to demand a coordinated two-line change — because the "obvious" fix would ship a _different_ invalid state instead of the current one. That happened to me recently with a ZUGFeRD hybrid PDF: the invoice endpoint was hardcoding the wrong e-invoice profile, and simply removing that hardcode would have produced a PDF that was internally inconsistent with its own metadata. Here's the story.

## The Setup: Hybrid PDFs, Two Profiles, One Print Endpoint

If you haven't worked with German e-invoicing before: ZUGFeRD (and its French twin Factur-X) is a hybrid format. Visually it's an ordinary PDF/A-3 that a human can read. Structurally, it also has a machine-readable XML file embedded inside, plus XMP metadata in the PDF header declaring _which_ e-invoice standard that XML conforms to.

Two profiles matter for us:

- **EN 16931** — the pan-European invoice standard. Fine for most B2B.
- **XRechnung** — Germany's public-sector (B2G) profile. If you're invoicing a public authority, you must use XRechnung and include a _Leitweg-ID_ (buyer reference, business term `BT-10`).

Our system already generated both flavors correctly for the _standalone_ XML export endpoint. But the _print_ endpoint — `POST /:invoiceId/pdf?zugferd=true`, which produces the hybrid PDF — had this:

```typescript
// invoice.service.ts — the offending line
const xml = await this.buildXInvoiceXml(invoice, {
  profile: XInvoiceProfileEnum.EN16931, // always. no matter what.
});
```

So B2G buyers configured for XRechnung — the ones who actually _require_ it — were quietly receiving EN 16931 PDFs from the print flow, while getting correct XRechnung XML from the export flow. Same invoice, two different profiles depending on how you fetched it.

## The Trap: Just Remove the Hardcode?

The reflex fix is to pass `undefined` and let the resolver figure it out. We already had an `XInvoiceContextBuilder.resolveProfile()` that walks a priority chain: explicit request → buyer's `billingProfile.xInvoiceProfile` → inferred from the Leitweg-ID → default to EN 16931. So:

```typescript
const xml = await this.buildXInvoiceXml(invoice, {
  profile: undefined, // let the resolver decide
});
```

Ship it? Not yet. Before touching it, I traced where the resolved XML was going, and found this in the XMP metadata builder:

```typescript
// zugferd-xmp.factory.ts — the second hardcode
const xmp = buildXmpPacket({
  conformanceLevel: "EN 16931",
  version: "1.0",
  // ...
});
```

The XMP packet — the metadata _the PDF itself declares about the embedded XML_ — hardcoded EN 16931 too. So the "fix" would have produced an XRechnung 3.0 XML document embedded inside a PDF whose own metadata claimed it was EN 16931 1.0. A validator reading the metadata would see one thing; a validator reading the payload would see another. That's arguably _worse_ than the original bug, because now the PDF is internally lying about itself.

The two hardcodes had to change together, or not at all.

## The Fix: Threading the Profile Through Two Layers

The change ended up touching three files, but the shape is simple: resolve the profile once, then thread it through both the XML builder and the metadata builder.

```typescript
// invoice.service.ts
const { xml, profile } = await this.buildXInvoiceXml(invoice, {
  profile: undefined, // resolver decides
});

const pdf = await this.zugferdEmbedder.embed(basePdf, {
  xml,
  profile, // <-- now flows into the XMP packet too
  filename: "factur-x.xml",
});
```

The XMP factory then maps the profile onto the correct conformance level and version:

```typescript
// zugferd.constants.ts
export const ZUGFERD_CONFORMANCE_LEVEL_MAP = {
  [XInvoiceProfileEnum.EN16931]: "EN 16931",
  [XInvoiceProfileEnum.XRECHNUNG]: "XRECHNUNG",
} as const;

export const ZUGFERD_VERSION_MAP = {
  [XInvoiceProfileEnum.EN16931]: "1.0",
  [XInvoiceProfileEnum.XRECHNUNG]: "3.0",
} as const;
```

Those constants aren't guessed. Before writing them, I opened real XRechnung ZUGFeRD 2.5 PDFs from our fixture corpus, extracted their XMP packets, and confirmed `fx:ConformanceLevel=XRECHNUNG` and `fx:Version=3.0` were what real-world tools produce. The alternative — reading the spec and hoping — would have shipped subtly wrong metadata that no automated test in our codebase would catch.

`IZugferdXmpInput` and `IZugferdEmbedMeta` both got `profile` promoted from "implied" to required, so TypeScript would break the build if any future call site forgot to pass it. That's the change I'm most happy with: it converts a runtime invariant ("these two must agree") into a compile-time one.

## Lessons: Trace the Whole Blast Radius Before "Just Fixing It"

Two things stood out that I want to internalize:

**1. When you delete a hardcoded value, grep the constant across the whole module before shipping.** The EN 16931 profile was hardcoded in two places that had to move together. Fixing only one produced a _different_ wrong state, not a right one. That's the class of bug where a "small PR" causes a regression precisely because it looks small enough to not warrant a proper trace-through. Ten minutes of grepping before writing any code saved a follow-up hotfix.

**2. Validate against real artifacts, not against your reading of the spec.** I could have written `"3.0"` because the XRechnung spec says the current version is 3.0. Instead I extracted the actual XMP from PDFs that already validate cleanly at customer sites. The two agreed here, but they don't always — real-world tools sometimes lag or extend the spec, and if you're trying to produce PDFs that match what customers already accept, the artifacts are the source of truth. Test corpora exist for a reason.

## Closing

The one-line version of this story is "resolve the profile from the buyer instead of hardcoding it." The five-line version is "resolve the profile, thread it through XML and metadata together, verify against real fixtures, promote the invariant into the type system, and only _then_ ship." I'd rather write the five-line version once than the one-line version followed by a hotfix.

If you're building anything that generates PDF/A-3 hybrid documents — ZUGFeRD, Factur-X, or even PDF/UA — take a moment to check whether your payload and your metadata are being computed from the same source of truth. If two places have to agree and no test enforces it, they will eventually disagree. Ask me how I know.
