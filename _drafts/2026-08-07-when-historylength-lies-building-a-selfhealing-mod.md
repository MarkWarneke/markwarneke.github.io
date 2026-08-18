---
layout: post
title: "When history.length Lies: Building a Self-Healing 'Modified' Signal"
subtitle: "Why counting change events is the wrong way to detect drift between synced records"
tags: [NestJS, MongoDB, API Design, Data Modeling, Backend]
comments: true
time: 5
---

There's a class of bug that only shows up after a feature has been in production long enough for the data to grow up. The code is correct on day one. It's correct on day two. Then, quietly, six weeks later, a signal that everyone on the team relies on turns into noise — and by the time anyone notices, the UI is showing the same warning on every row and users have learned to ignore it.

I hit exactly that this week while building an admin content-distribution system, and the fix taught me something worth writing down: **prefer state comparisons over event counting when you need to know if two things are still in sync.**

## The Setup: One Rule, Many Copies

The system in question lets admins author a "document rule" once in a central library, then push copies of it out to any number of tenant accounts. Once distributed, each tenant owns their copy — they can edit it, disable it, add tags. Later, if the admin updates the master rule, they can push the new text out to any subset of tenants who already have a copy linked.

That last step is the risky one. If a tenant has customised their copy — reworded a sentence, added domain-specific terminology — a blind overwrite destroys their work. So the admin UI shows a list of every tenant implementing a given rule, and each row carries a `modified` flag: *has this tenant edited their copy since it was linked?* If yes, we surface a warning and open a side-by-side reconcile dialog instead of doing a straight push.

The flag drives real behaviour. Getting it wrong doesn't just mislead the UI — it can silently overwrite customer edits.

## The Naive Signal

The first implementation was the obvious one. Every write to a rule appends an entry to a `history` array with the prior text, the author, and a timestamp. If a tenant has ever edited their copy, `history.length > 0`. So:

```typescript
const isModified = partnerRule.history.length > 0;
```

Ship it. Tests pass. The distribute flow works. The reconcile dialog opens on the right rows.

Then the bug: an admin pushes an updated rule to twenty tenants. All twenty rows now show "Modified." The admin pushes again the next day. Still "Modified." Everyone. Forever.

Here's why. The `applyToPartnerRule` service — the very thing that pushes admin content down to a tenant's copy — snapshots the *previous* text into `history` before overwriting. That's correct behaviour: we want an audit trail even for admin-initiated writes. But it means the admin's own push increments `history.length`, which flips the flag on. From that moment on, the copy is indistinguishable from one the tenant actually customised.

The signal was measuring the wrong thing. `history.length > 0` answers "has this record ever been written to more than once?" — a question nobody was asking. The real question was "does this tenant's current text differ from what the admin currently has?" A count of past events cannot answer a question about present state.

## The Fix: Compare What You Actually Care About

The replacement is one line:

```typescript
const isModified = partnerRule.rule.trim() !== adminRule.rule.trim();
```

That's the whole change to the flag itself. But the interesting part isn't the comparison — it's the second-order design decision it forced.

If `isModified` is defined as "partner text differs from admin text," then any field the admin sync touches becomes part of that definition. If the admin push also overwrites `tags` and `severity` and `description`, then every field the tenant might customise on their own copy has to be included in the comparison, or the flag lies in the other direction. That way lies madness — every new field added to the schema becomes a maintenance burden on the drift check.

So we narrowed what admin-to-tenant sync actually copies:

```typescript
async applyToPartnerRule(
  adminRuleId: string,
  partnerId: string,
  partnerRuleId: string,
  userId?: string,
): Promise<DocumentRule> {
  const adminRule = await this.assertFindOne(adminRuleId);
  await this.documentRuleService.assertFindOneLinkedToAdminRule(
    partnerId,
    partnerRuleId,
    adminRuleId,
  );

  // Only the rule text propagates. Tags, description, severity,
  // active flag, and cost config stay tenant-owned.
  return this.documentRuleService.setRuleText(
    partnerId,
    partnerRuleId,
    adminRule.rule,
    userId,
  );
}
```

`tags`, `description`, `severity`, and `active` are now permanently tenant-owned. The admin can't accidentally clobber them, the `modified` flag only tracks the one field that sync actually touches, and the concept "modified" now has a crisp, defensible definition instead of an accidental one.

The bonus property is that the flag **self-heals**. Push the admin's current text to a diverged tenant, their text now matches, `isModified` flips back to false — automatically, without any explicit reset logic, without a flag to clear, without a background job to reconcile stale state. The signal is derived from the data, not stored alongside it, so it can't drift out of sync with reality.

## The Lesson: Derived State Beats Stored State

Two things I'd internalise from this:

**Signals should describe present state, not past events.** `history.length` is an event counter. "Is this modified?" is a state question. Whenever a metric answers a different question than the one being asked, the answer is coincidentally right until it isn't — and when it stops being right, the failure is silent. If you can derive the signal from a direct comparison of current values, do that instead. It costs a string comparison per row and buys you a metric that is *definitionally* correct.

**Design your write paths around what your read paths need to be able to say.** The scope of admin-to-tenant sync used to be "everything on the rule." Narrowing it to "just the text" wasn't a feature reduction — it was what let the drift signal make sense at all. When you catch yourself adding fields to a shared write path, ask what invariant that widens or breaks for readers.

## Closing Thought

The best bug fixes are the ones where you delete a line of state, not add one. `history.length > 0` looked like a legitimate use of data we were already storing — free signal, no extra columns, one line of code. In practice it conflated "someone wrote to this" with "someone changed this," and the two diverged the moment sync stopped being a one-way street. A single equality check, plus a tighter contract on what sync means, replaced it with a signal that maintains itself. I'll be looking harder for `.length > 0` checks in every codebase I touch from now on.

Have you hit a similar "the metric was correct until the system grew up" moment? I'd love to hear about it.
```
