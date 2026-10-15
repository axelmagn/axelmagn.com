# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is the **colorized** Zola theme — both the theme source and its demo site (demo.colorized.life). It is a dark-pastel theme with a 6-color accent palette. The repo serves double duty: it's consumed as a git submodule by other Zola sites, and it builds directly as its own demo site.

## Build & Develop

```sh
zola build          # build to public/
zola serve          # dev server with live reload (default: http://127.0.0.1:1111)
```

There are no tests, linters, or CI pipelines. Validation is visual — use `zola serve` and check the browser.

## Deployment

`deploy/post-receive` is a git hook for push-to-deploy. On push to `main`, it clones into a temp dir, runs `zola build`, copies the output to a timestamped release under `/srv/www/releases/demo.colorized.life/`, and atomically swaps the symlink. Keeps the 3 most recent releases.

## Architecture

### Color System (three layers)

1. **Sass defaults** (`sass/_variables.scss`): `$bg`, `$accent`, `$pink`, etc. with `!default` — the compile-time source of truth.
2. **CSS custom properties** (`sass/_theme-vars.scss`): maps Sass vars to `--bg`, `--accent`, etc. on `:root`. All styles reference `var(--name)`.
3. **Runtime overrides** (`templates/partials/theme_overrides.html`): if `[extra.colors]` is set in `zola.toml`, injects a `<style>` block that overrides the CSS custom properties. This lets site operators change colors without touching Sass.

All color references in Sass/CSS should use `var(--name)`, never raw `$var` values (except in `_variables.scss` and `_theme-vars.scss` themselves).

### Template Hierarchy

- `index.html` — standalone landing page (does **not** extend `base.html`; shares `partials/head_common.html`)
- `base.html` — layout shell for all other pages; provides named blocks for extension
- Page templates (`page.html`, `post.html`, `about.html`, `blog.html`, `palette.html`, `status.html`, `tags/single.html`, `tags/list.html`) extend `base.html`
- `partials/` — reusable includes (favicons, reduce-motion init + toggle, nav feed icon, head common, copyright, theme overrides)
- `shortcodes/` — Zola shortcodes (shimmer, ascii, image, codeline, hr)

### Sass Organization

`sass/style.scss` is the entrypoint. Partials are organized by scope:
- **Design tokens & assets**: `_variables`, `_theme-vars`, `_icons`, font faces
- **Shared foundations**: `_base`, `_typography`, `_code`, `_table`, `_scrollbar`, `_chrome`
- **Shared components**: `_alerts`, `_toc`, `_post-list`, `_shimmer`, `_images`, `_pagination`
- **Page-specific**: `_landing`, `_about`, `_palette`, `_post`

### Reduce-Motion System

The theme respects `prefers-reduced-motion` and provides a toggle button. The preference is stored in a `reduce-motion` cookie. Setting `cookie_domain` in `[extra]` shares the preference across subdomains. The toggle adds/removes the `reduce-motion` class on `<html>`. A blocking script in `<head>` reads the cookie before paint to avoid animation flash.

### Configuration

All theme options live under `[extra]` in `zola.toml`. The authoritative reference for available options and their defaults is `theme.toml`.

## Common Pitfalls

### Tera Whitespace Injection

Tera (Zola's template engine) preserves whitespace around `{% %}` tags. This creates invisible text nodes inside HTML elements that add unwanted width/spacing. Always use whitespace-trimming delimiters (`{%-` and `-%}`) when output must be tight against surrounding markup, especially inside inline elements like `<span>` and `<a>`.

### CSS Inheritance from Global Selectors

`sass/_chrome.scss` styles bare element selectors inside `nav` (e.g., `nav a { margin-right: 1.5rem }`). These apply to **all** `<nav>` elements, not just the site header nav. When creating new templates with their own `<nav>`, explicitly reset inherited properties (margins, font-family, font-size) in the component's own Sass partial.
