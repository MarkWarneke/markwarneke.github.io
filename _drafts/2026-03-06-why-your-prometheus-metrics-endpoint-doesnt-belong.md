---
layout: post
title: "Why Your Prometheus Metrics Endpoint Doesn't Belong on Your API Port"
subtitle: "Building a production-safe observability stack for NestJS microservices on Kubernetes"
tags: [DevOps, Prometheus, NestJS, Kubernetes, Observability, Node.js, Azure]
comments: true
time: 5
---

You've just instrumented your application with Prometheus metrics. You hit `curl localhost:3000/metrics` and a wall of beautifully formatted histograms and counters scrolls past your terminal. Feels great. Ship it.

Except you've just exposed CPU utilization, memory consumption, per-endpoint latency distributions, and error rates on the same port that serves your public API. Anyone who guesses `/metrics` now has a detailed map of your service's internals. We made this exact mistake across 10 NestJS microservices — and the fix was more interesting than we expected.

## The Setup: RED Metrics for Every Service

We wanted per-endpoint RED metrics (Rate, Errors, Duration) across our entire backend. The implementation itself was straightforward: a shared `PrometheusModule` using `prom-client` with a dedicated `Registry`, an interceptor to record `http_request_duration_seconds` with `method`, `route`, and `status_code` labels, and a controller to serve the `/metrics` endpoint. Every NestJS app module imports `PrometheusModule`, gated by a `PROMETHEUS_ENABLED` env var.

```typescript
// prometheus.interceptor.ts (simplified)
@Injectable()
export class PrometheusInterceptor implements NestInterceptor {
  constructor(private readonly prometheusService: PrometheusService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const start = Date.now();
    const req = context.switchToHttp().getRequest();

    return next.handle().pipe(
      tap(() => {
        const res = context.switchToHttp().getResponse();
        const duration = (Date.now() - start) / 1000;
        this.prometheusService.recordHttpRequest(
          req.method,
          req.route?.path || req.path,
          res.statusCode,
          duration,
        );
      }),
    );
  }
}
```

We added Prometheus scrape annotations to every pod template and enabled Azure Managed Prometheus on the AKS cluster. Within an hour, metrics were flowing. The problem? They were flowing to anyone with a browser, too.

## The Problem: Metrics on the Public Surface

The `/metrics` endpoint sat behind the same ingress as our API. That means `https://api.example.com/v1/metrics` was publicly reachable. Internal runtime data — heap size, event loop lag, request latency percentiles broken down by endpoint — all of it served with a 200 OK to anyone who asked.

Our first instinct was to block it at the ingress layer. We added an nginx `configuration-snippet` annotation to return 403 for any request URI containing `/metrics`:

```yaml
nginx.ingress.kubernetes.io/configuration-snippet: |
  if ($request_uri ~* "/metrics") {
    return 403;
  }
```

This failed immediately. Our nginx-ingress controller had `allow-snippet-annotations: false` (as it should — snippet injection is a well-known attack vector in older nginx-ingress versions). Flux rejected the manifests, and we were back to square one.

The ingress-level approach was wrong anyway. Even if it had worked, we'd be relying on a negative rule ("block this one path") rather than a positive architecture ("metrics are never exposed externally in the first place"). The correct solution is the **dual-port pattern**: serve your application on one port and your metrics on another, and never route the metrics port through ingress.

## The Dual-Port Pattern

We deleted the `MetricsController` entirely and moved metrics serving into the `PrometheusService` itself, spinning up a raw `http.Server` on a dedicated port:

```typescript
// prometheus.service.ts
@Injectable()
export class PrometheusService implements OnModuleInit, OnModuleDestroy {
  private metricsServer: http.Server;
  private readonly registry = new Registry();
  private readonly port: number;

  constructor(private readonly configService: ConfigService) {
    this.port = parseInt(configService.get('PROMETHEUS_METRICS_PORT') || '9464');
  }

  async onModuleInit() {
    this.metricsServer = http.createServer(async (req, res) => {
      if (req.url === '/metrics' && req.method === 'GET') {
        res.setHeader('Content-Type', this.registry.contentType);
        res.end(await this.registry.metrics());
      } else {
        res.writeHead(404);
        res.end();
      }
    });
    this.metricsServer.listen(this.port);
  }

  async onModuleDestroy() {
    await new Promise<void>((resolve) =>
      this.metricsServer.close(() => resolve()),
    );
  }
}
```

Port 9464 was chosen to match the [OpenTelemetry Prometheus exporter convention](https://opentelemetry.io/docs/specs/otel/compatibility/prometheus_and_openmetrics/). The key properties of this approach:

- **The main API port returns 404 on `/metrics`** — no internal data leaks even if ingress rules are misconfigured.
- **No ingress route needed** — Prometheus scrapes pods directly via the pod IP on port 9464, which is cluster-internal by default.
- **No NestJS middleware overhead** — the metrics server is a plain `http.Server`, no authentication guards, no throttling, no request logging. It starts and stops via NestJS lifecycle hooks, so it's still managed by the framework.

On the Kubernetes side, we updated every pod annotation to point at the new port:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "9464"
```

We also filtered `/metrics` spans from Application Insights using a custom `SpanProcessor`. Without this, every 15-second Prometheus scrape across 10 services would generate telemetry noise that drowns out actual user traffic.

## The Infrastructure Side: More Than Just a Port Change

Getting the metrics *collected* was only half the battle. We were simultaneously migrating our Terraform AzureRM provider from 3.x to 4.x — partly because Grafana and Managed Prometheus provisioning required features only available in 4.24+. The migration was its own adventure (AAD profile resets, deprecated property renames, diagnostic settings overhaul), but the end result was a fully managed stack: Azure Monitor workspace for Prometheus storage, data collection rules linking AKS to the workspace, and Managed Grafana v11 for dashboards.

One detail that caught us: we needed a `ama-metrics-settings-configmap` to enable annotation-based pod scraping for application namespaces. Without it, Azure Managed Prometheus only collects infrastructure metrics — it won't discover your `prometheus.io/scrape` annotations unless you explicitly opt in your namespaces.

## Lessons Learned

**Don't bolt security onto observability — design it in.** The ingress-blocking approach was a band-aid. The dual-port pattern is a proper architectural boundary: metrics never touch the public network path, period. This is one of those cases where the "right" solution is also the simpler one.

**Convention matters.** Using port 9464 and standard `prometheus.io/*` annotations meant zero custom configuration in our Prometheus setup. When your tooling expects certain patterns, following them eliminates an entire category of debugging.

**Filter your telemetry pipelines.** If you're running both Prometheus and an APM tool (Application Insights, Datadog, etc.), the scrape traffic will pollute your APM data. A span processor that drops `/metrics` requests takes five minutes to write and saves you from misleading latency dashboards forever.

**Test the full path, not just the endpoint.** Our metrics endpoint worked locally for weeks before we discovered the ingress exposure issue. The gap between "it works in dev" and "it's production-safe" was entirely in the network topology.

## What's Next

With RED metrics flowing, the next step is building out Grafana dashboards for p50/p95/p99 latency by service and route, and setting up alerting rules for error rate spikes. The infrastructure is in place — now it's about turning data into actionable signals. If you're running NestJS services on Kubernetes, I'd strongly recommend the dual-port pattern from day one. It's a small amount of code that eliminates an entire class of security concerns before they start.
