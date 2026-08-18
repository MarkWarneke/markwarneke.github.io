---
layout: post
title: "Shipping /llms.txt Without Silently Breaking Production"
subtitle: "What an adversarial review of a Jekyll content pipeline taught me about HTML entities, URL collisions, and build-time validation"
tags: [Jekyll, LLMs, CI/CD, Ruby, Static Sites, Build Validation]
comments: true
time: 5
---

A few weeks ago I sat down to add `/llms.txt` and `/llms-full.txt` to one of our marketing sites. The [llmstxt.org](https://llmstxt.org) standard is refreshingly simple: two plain-text files at the root of your domain that describe your content in a way LLM crawlers and agent frameworks can reliably consume. `llms.txt` is a curated index; `llms-full.txt` is the full corpus concatenated in a single document. Give an agent one URL and it can bootstrap an understanding of your site without scraping HTML.

I expected the whole thing to be a two-hour job — write a Jekyll template, iterate over `site.posts`, ship it. What actually happened was closer to a full day of edge cases, an ugly URL collision hiding in five-year-old content, and a post-build validation script that has since caught more bugs than the feature itself. This post is about that gap between "generate a text file" and "generate a text file you can trust."

## The Challenge

On paper, generating `llms.txt` from a Jekyll site is straightforward. You already have `site.posts`, each post has a title, a URL, and a body. Loop, format, done. The trouble starts when you look closely at what "title" and "body" actually contain by the time they reach your template.

Jekyll's `strip_html` filter leaves HTML entities behind — `&amp;`, `&#8217;`, `&quot;` — because it only removes tags, not entity encodings. `normalize_whitespace` collapses runs of spaces, but if you run `strip_newlines` before it, two words separated only by a `\n` get glued together into one nonsense token. Multiple posts can canonicalize to the same URL if slugs differ only in Unicode normalization form (NFC vs NFD) or URL-encoding of the same character. And if any post in your archive has malformed front matter, Jekyll will happily render the raw YAML as post content and then serve two posts at the same permalink, one of which will silently win.

None of this is theoretical. Every single one of those bugs shipped into my first draft of `llms.txt`. The file looked plausible when I opened it. It was wrong in ways I would never have noticed from eyeballing it.

## The Approach

The core generation is a Jekyll template that walks `site.posts`, filters by `noindex`, and emits one line per post. Nothing exotic:

```liquid
{%- for post in site.posts -%}
  {%- if post.noindex == true -%}{%- continue -%}{%- endif -%}
  {%- assign description = post.description
      | default: post.excerpt
      | strip_html
      | normalize_whitespace
      | truncate: 200 -%}
- [{{ post.title | strip_html }}]({{ post.url | absolute_url }}): {{ description }}
{%- endfor -%}
```

That's the happy path. The interesting work is everything wrapped around it.

**HTML entity decoding.** After `strip_html`, I run the output through a small filter that decodes entities so `Don&#8217;t` becomes `Don't`. Otherwise an LLM parsing the file sees literal character references and treats them as content — sometimes even hallucinating that the site is intentionally teaching HTML.

**Whitespace order matters.** The correct pipeline is `strip_html | normalize_whitespace | truncate`. Dropping `strip_newlines` from the middle sounds like a nit, but leaving it in turns `Hello\nworld` into `Helloworld` before normalization gets a chance to convert the newline to a space. I lost twenty minutes to that one before I noticed a description that read `AbrechnungsprozessOptimierung`.

**URL canonicalization.** For the validator I compare slugs URI-decoded and Unicode-normalized to NFC. Two posts whose filenames differ only in whether `ä` is one code point or `a` + combining diaeresis will otherwise resolve to the same permalink without anything flagging it.

**Deduplication in `llms-full.txt`.** Even after fixing the source, I dedupe by canonical URL when concatenating full post bodies. It's belt-and-suspenders, but it means a future collision doesn't silently double-emit a post.

The piece I'm most glad I built is the post-build validator. It's a small Ruby script that runs against `_site/` in CI:

```ruby
posts = site_posts_expected_in_llms_txt(config)
llms  = File.read(File.join(dest, "llms.txt"))
full  = File.read(File.join(dest, "llms-full.txt"))

posts.each do |post|
  url = canonicalize(post.url)
  assert llms.include?(url), "missing in llms.txt: #{url}"
  assert full.include?(url), "missing in llms-full.txt: #{url}"
  assert !full.include?(entity_leak(post)),
         "HTML entity leaked into llms-full.txt for #{url}"
end

assert_no_duplicate_urls(full)
assert full.end_with?("\n"), "llms-full.txt must end with a trailing newline"
assert_no_excluded_posts_present(llms, config)
```

The checks are unglamorous — every included post appears exactly once, no `noindex` posts leaked in, no HTML entities survived, the file ends with a newline so `cat` and diffs behave — but each one corresponds to a specific mistake I actually made. The validator runs twice in CI: once against a root-domain build, once against a project-subpath build. Absolute-URL bugs love to hide when you only test one deployment mode.

## The Collision That Wasn't Supposed to Exist

The most instructive bug wasn't in the new code. Deep in the `_posts` directory there was a four-line file from 2022 with an unclosed front-matter block — someone had started a draft, saved, and moved on. Jekyll rendered its raw YAML as the post body and assigned it the same permalink as a properly-formatted post published three days later. For years, the site had been serving two posts at one URL. Nobody had noticed because whichever post lost the race just didn't render, and no link on the site pointed to the loser.

The `llms.txt` pipeline noticed immediately, because the validator counted two entries with the same canonical URL and refused to pass. Deleting the fragment fixed both the new file and a rendering bug that had been in production for four years. That, more than the feature itself, is what convinced me build-time validators earn their keep.

## Lessons Learned

If I were doing this again, I would write the validator first. The generator is a hundred lines of Liquid; the validator is what turns those hundred lines into something I trust. Build-time assertions are the cheapest tests you can write against a static site — they run on artifacts that already exist, they need no fixtures, and every failure is reproducible.

The other lesson is that "adversarial review" pays off in exactly the situations where it feels most excessive. I asked a colleague to try to break the pipeline before merging, and every fix in the final PR — entity decoding, dedup, whitespace order, absolute URLs for the full-text pointer — came from that review, not from my own testing. When the output is text meant for machines, human intuition about what "looks right" is a bad safety net.

## Wrapping Up

`llms.txt` is a small standard doing useful work: it gives agents a stable, structured entry point into your content without forcing them to scrape HTML. Generating it isn't hard. Generating one you'd stake production on requires taking Unicode, HTML entities, and URL collisions seriously — and the cheapest way to take them seriously is a validator that fails your build when they show up. If you're shipping content to LLMs, I'd love to hear what edge cases have bitten you.
```
