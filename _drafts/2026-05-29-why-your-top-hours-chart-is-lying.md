```
---
layout: post
title: "Why Your 'Top Hours' Chart Is Lying"
subtitle: "Chronological axes, zero-fill, and the quiet bugs that make analytics dashboards unreadable"
tags: [Vue, ECharts, data-visualization, frontend, analytics, UX]
comments: true
time: 5
---

There's a particular kind of dashboard that looks fine in a screenshot, passes code review, and ships — and then sits in production confusing every person who opens it. Ours was a call analytics dashboard. It had all the right widgets: a time-series chart, a calendar heatmap, KPI tiles, and two distribution charts labelled "Top Hours" and "Top Weekdays." It rendered. It had no errors. And nobody could actually read it.

The trigger for the rebuild was a partner manager asking, in a meeting, "so when *do* most calls come in?" I opened the dashboard, looked at the Top Hours chart, and realized I couldn't answer her. The chart had bars for 9, 14, 17, and 11 — in that order, sorted by value, with no bars at all for hours that had zero calls. It was technically a chart of "the top hours." It just wasn't a chart of *when calls come in*, which is what anyone looking at it actually wants to know.

## The Challenge

Once I started pulling on the thread, the problems multiplied:

- **30-day default range.** For low-volume partners, 30 days of data looked like noise. Weekly patterns — the thing you most want to see in a call dashboard — were invisible. Quiet partners looked dead.
- **Line charts on sparse data.** A line chart connecting (Mon: 2 calls) → (Tue: 0) → (Wed: 3) collapses day-to-day variance into a flat-looking squiggle. Bars at the same scale immediately show you which days were busy.
- **Value-sorted categorical axes.** The hour-of-day chart was ordered by count, not by hour. So `[14, 9, 17, 11]` was the x-axis. You can't read a time-of-day distribution off that. Same problem for weekdays.
- **Missing buckets.** The backend returned only hours and weekdays that had at least one call. If nobody phoned at 3am, hour 3 was missing entirely — not "0," missing. Combined with the value-sort, this meant the chart's x-axis was a different set of categories every time you opened it.
- **A KPI label-wrapping bug** where labels like "Wiederkehrende Anrufer" wrapped onto two lines because of a nested Vuetify `v-col` width constraint, making the whole row look broken at first glance.

Individually, none of these is dramatic. Together, they made the dashboard noise. And critically, every one of them had been "working as implemented" — it was the *spec* that was wrong, not the code.

## The Approach

The fix was a rewrite of the chart-data utilities and a careful pass over the ECharts options. Two principles drove the work: **time axes are chronological, always**, and **distribution charts must always render every bucket**, even empty ones.

The first piece was zero-filling. For hour-of-day and weekday charts, the backend's "only return hours that had calls" behaviour is reasonable as an API, but disastrous as a chart input. So we normalized at the boundary:

```typescript
type HourBucket = { hour: number; count: number };

export function zeroFillHours(buckets: HourBucket[]): HourBucket[] {
  const byHour = new Map(buckets.map(b => [b.hour, b.count]));
  return Array.from({ length: 24 }, (_, hour) => ({
    hour,
    count: byHour.get(hour) ?? 0,
  }));
}

export function zeroFillWeekdays(buckets: WeekdayBucket[]): WeekdayBucket[] {
  // 1 = Monday … 7 = Sunday, matching ISO-8601
  const byDay = new Map(buckets.map(b => [b.weekday, b.count]));
  return Array.from({ length: 7 }, (_, i) => ({
    weekday: i + 1,
    count: byDay.get(i + 1) ?? 0,
  }));
}
```

Boring, two-line functions. They are also the entire reason the chart is now legible. The chart component no longer has to know anything about whether 3am had calls; it always receives 24 buckets in ascending order. We codified this in unit tests so a future "optimization" can't remove it:

```typescript
it("returns all 24 hours in chronological order, zero-filling gaps", () => {
  const input = [{ hour: 9, count: 12 }, { hour: 17, count: 8 }];
  const result = zeroFillHours(input);

  expect(result).toHaveLength(24);
  expect(result.map(r => r.hour)).toEqual([...Array(24).keys()]);
  expect(result[3].count).toBe(0);
  expect(result[9].count).toBe(12);
});
```

The second piece was the chart itself. We were using a shared `TimeSeriesLineChartCard` component built on ECharts. Rather than fork it into a bar version, we taught it to accept a `type` on each series and toggle `boundaryGap` accordingly — line charts want `boundaryGap: false` so they hit the axis edges; bar charts need `true` so the bars don't get clipped at the chart boundary:

```typescript
const seriesConfig = computed(() =>
  props.series.map(s => ({
    name: s.name,
    type: s.type ?? "line",
    data: s.data,
    smooth: s.type === "line",
  })),
);

const xAxisConfig = computed(() => ({
  type: "time",
  boundaryGap: props.series.some(s => s.type === "bar"),
}));
```

The same component now drives both the calls-over-time chart (bars, 90-day window) and the existing line-chart use cases elsewhere in the portal, with no duplicated code.

The third piece was structural: promoting analytics from a buried action at the bottom of a row context menu to a first-class **"Anrufe"** tab on the partner analytics page, gated by the `READ:call` permission. The technical change was small — a route, a tab, a permission check — but it sent a clear signal that this dashboard is a primary view, not an easter egg.

## Lessons Learned

The biggest takeaway: **a chart that renders is not a chart that communicates.** Every one of these issues passed type checks, lint, and review. The bug was in the gap between "the data the API returns" and "the data a human can read." That gap belongs to the frontend, and it's worth writing dull little normalization functions to close it.

The second takeaway is about defaults. Switching the default range from 30 to 90 days was a one-line change with disproportionate impact, because *defaults are the product*. Most users never touch the date picker. Whatever you default to is what your dashboard is, for the median viewer. Pick the window that tells the truest story for the typical user, not the one that minimizes initial load.

Finally: **kill the value-sort on time-shaped axes.** "Top hours" is a tempting label, but if the chart's job is to answer "when," the axis must be time. If you genuinely want a ranking, use a separate widget — don't overload one chart with two questions.

## Closing

Dashboards rot quietly. They don't throw errors when they mislead you; they just slowly stop being opened. The cure isn't glamorous — it's chronological axes, zero-filled buckets, sensible defaults, and the willingness to ask "could a stranger actually read this?" before shipping. If you have an analytics surface that nobody seems to use anymore, that question is usually a good place to start.

```
