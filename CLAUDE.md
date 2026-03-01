# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jekyll-based personal blog and portfolio for Mark Warneke, deployed to GitHub Pages at markwarneke.me. Built on the Beautiful Jekyll theme by Dean Attali.

## Build & Development Commands

All local development uses Docker via Makefile (Jekyll 3.7.3):

```bash
make serve          # Build and serve locally at http://localhost:3000 (cleans container first)
make serve-drafts   # Serve with draft posts included
make build          # Build static site only
make clean          # Remove Docker container
```

The site auto-rebuilds on file changes when using `make serve`.

## CI

GitHub Actions runs `markdown-link-check` on push/PR to master (`.github/workflows/main.yml`).

## Architecture

- **Static site generator**: Jekyll with `github-pages` gem (v197)
- **Layouts** (`_layouts/`): `base.html` → `default.html` → `post.html`/`page.html`/`minimal.html`
- **Includes** (`_includes/`): Reusable components (nav, header, footer, disqus, analytics, social-share)
- **Data** (`_data/`): `SocialNetworks.yml` (social link icons/URLs), `ui-text.yml` (UI strings)
- **Styling**: Bootstrap + custom CSS in `css/main.css`
- **JS**: jQuery 1.11.2 + Bootstrap + custom `js/main.js` (navbar scroll behavior, image carousel, scroll-to-top)

## Blog Post Conventions

Posts live in `_posts/` with naming: `YYYY-MM-DD-Title.md`

Required front matter:
```yaml
---
layout: post
title: "Post Title"
subtitle: "Optional subtitle"
image: /img/example.jpeg      # Header/card image
share-img: /img/example.jpeg  # Social sharing image
tags: [Azure, DevOps]
comments: true
time: 5                       # Reading time in minutes
---
```

Posts default to `layout: post`, `comments: true`, and `social-share: true` via `_config.yml` defaults.

## Key Configuration (`_config.yml`)

- **Permalink**: `/:year-:month-:day-:title/`
- **Markdown**: kramdown with GFM input
- **Highlighter**: rouge
- **Pagination**: 15 posts per page
- **Plugins**: jekyll-paginate, jekyll-sitemap, jekyll-gist
- **Analytics**: Google Analytics (UA-70835200-1)
- **Comments**: Disqus (shortname: markwarneke)

## Content Pages

- `index.html` — Homepage
- `blog.html` — Card-based blog listing with custom CSS grid
- `about.md` — Biography and professional background
- `contact.md` — HubSpot embedded contact form
- `talks.html` — Conference presentations (PDFs in `talks/`)
- `tags.html` — Tag index page

## Assets

- Images go in `img/` (subdirs: `original/`, `posts/`, `cert/`)
- Code samples in `code/` (PowerShell scripts, ARM templates, Pester tests)
- Talk PDFs in `talks/`
