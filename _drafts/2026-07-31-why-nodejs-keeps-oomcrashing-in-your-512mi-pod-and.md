---
layout: post
title: "Why Node.js Keeps OOM-Crashing in Your 512Mi Pod (and the One-Line Fix)"
subtitle: "Node auto-detects cgroup limits — but the default it picks is smaller than you think"
tags: [Node.js, Kubernetes, NestJS, DevOps, Performance, V8]
comments: true
time: 5
---

Two of our dev-cluster services — a NestJS API for a THG (greenhouse gas quota) product and a voice-processing worker — started crash-looping on every deploy. The pods never became ready. Logs showed the same thing on repeat:

```
FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
```

No traffic. No user hitting an endpoint. The process was dying somewhere between "container started" and "NestJS finished wiring its DI graph." Both services had been fine in production for months. What changed?

Nothing, really. That was the interesting part.

## The Symptom That Made No Sense

Both deployments had a 512 Mi memory limit set on the container. That's not generous, but for a NestJS boot with the Azure SDK and Application Insights on top, it's usually enough headroom. Our production `thg` service ran happily inside the exact same limit.

What was different was that production had one specific environment variable set, and dev didn't:

```yaml
env:
  - name: NODE_OPTIONS
    value: "--max-old-space-size=384"
```

That was the entire difference. Copy that one line to the dev deployments and the crash loop stopped. But *why* did removing it break things when the container limit was identical?

The answer is a subtle piece of Node.js 18+ behavior that catches a lot of teams the first time they see it.

## What Node Actually Does When You Don't Set a Heap Limit

Before Node 12, if you didn't pass `--max-old-space-size`, V8 defaulted to a fixed number — around 1.4 GB on 64-bit systems — regardless of what the host or container allowed. That was fine on a laptop and a disaster on a small container: the process would happily allocate past the cgroup limit, get OOM-killed by the kernel, and leave you with a cryptic exit code 137.

Node 12 flipped the default so V8 would ask the OS about available memory and pick something reasonable. On Linux, "the OS" for a container means the cgroup. Since Node 14, and much more aggressively since Node 18, the runtime reads the cgroup memory limit and derives an old-space heap size from it.

The derivation is not "use all of it." V8 sizes the old-space at roughly **half of the detected limit** — the rest is reserved for the new-space (young generation), code space, native buffers, C++ heap, thread stacks, and the runtime itself.

Do the arithmetic for a 512 Mi container:

- Detected limit: 512 MiB
- Auto-derived old-space: ~256 MiB
- Everything else Node needs at startup: not negligible

A NestJS boot on Node 18 is not a lightweight event. It scans the module graph, instantiates every provider, hydrates the Azure SDK's HTTP pipeline, initializes Application Insights, opens telemetry exporters, and holds a lot of transient allocation while the DI container settles. It's entirely plausible to touch 250 MiB of old-space objects before the first HTTP handler is even registered.

When that peak lands during startup, V8 tries to grow old-space, hits its self-derived 256 MiB ceiling, runs a full mark-sweep, still can't free enough, and throws the fatal allocation error. Not the kernel OOM-killer. V8 itself, gracefully aborting because it thinks its heap budget is exhausted — even though the container has another 250-plus megabytes sitting unused.

## The Fix, and Why 75%

We set `NODE_OPTIONS=--max-old-space-size=384` on both dev deployments. That's 384 MiB — roughly 75% of the 512 Mi container limit — and it matched the ratio we already used in production for the same services.

```yaml
containers:
  - name: api
    image: mmmintelligence.azurecr.io/thg-api:latest
    resources:
      limits:
        memory: 512Mi
    env:
      - name: NODE_OPTIONS
        value: "--max-old-space-size=384"
```

Why 75% and not something higher? The 25% margin has to cover everything V8 doesn't count in old-space:

- **New space** (young generation) — typically 16–64 MiB depending on Node version and CPU count
- **Code space** for compiled JIT code
- **Off-heap Buffers** — `Buffer.allocUnsafe`, streams, network I/O
- **Native modules** — anything from `bcrypt` to gRPC keeps its own C++ heap
- **Thread stacks** — libuv workers, Worker Threads
- **Process overhead** — the Node binary itself, shared libraries, kernel-side page tables

If you set `--max-old-space-size` to the full container limit, you're telling V8 it can use every byte the container has — but V8's allocator can't see the other consumers. The kernel eventually notices, and you swap a graceful V8 abort for a much less graceful SIGKILL. 75% is the conservative shape of "let V8 use most of the container while leaving room for the parts V8 doesn't manage."

## What Actually Went Wrong Here

The interesting bug isn't "we forgot an env var." It's that we forgot it in *dev* while production was fine. Production had grown its `--max-old-space-size` over time, precisely because it had hit this exact class of problem earlier and someone fixed it. Dev never had. It only became visible now because startup weight had crept up — a couple more modules, a slightly heavier Azure SDK, a new Application Insights initializer — and finally pushed peak startup allocation past that auto-derived 256 MiB ceiling.

The lesson: environment parity matters, and JVM/V8 tuning is exactly the kind of thing that silently diverges between environments. If production has a heap flag, that flag exists for a reason. Copy it everywhere, or explicitly document why it doesn't apply.

## Takeaways

A few things I'd bake into any Node-in-Kubernetes setup from day one:

1. **Always set `--max-old-space-size` explicitly.** Don't rely on V8's cgroup auto-detection. It works, but it picks a value that's smaller than most people expect.
2. **Aim for roughly 75% of the container's memory limit.** Give room to native allocations, buffers, and code space.
3. **Match the flag across environments.** If prod has it, dev has it, and staging has it. Deltas here become invisible until a pod won't start.
4. **Distinguish V8 aborts from kernel OOM-kills.** `FATAL ERROR: JavaScript heap out of memory` is V8 giving up; exit code 137 is the kernel killing you. They have different fixes.

## Wrapping Up

A five-word environment variable resolved a crash loop that would have looked, at first glance, like an application bug or an infrastructure regression. It was neither — it was V8 doing exactly what it was designed to do, on a runtime whose default heap sizing has evolved three times in the last few major versions and will almost certainly evolve again.

If you run Node in a container, spend five minutes setting `--max-old-space-size` explicitly. Your future on-call self will thank you the next time a pod refuses to boot.
