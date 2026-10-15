+++
title = "Demo"
date = 2026-03-09
description = "A showcase of every rendering feature this site supports — typography, code, alerts, and color utilities."

[taxonomies]
tags = ["rust", "demo"]
+++


This page exists to exercise every visual element the site can render. If something looks off here, the styles need fixing. Think of it as a living reference sheet for the theme.

## Markdown

This is a regular paragraph. Nothing fancy — just body text flowing naturally across the full width of the container. It should be comfortable to read at any reasonable viewport width.

Here is **bold text** for strong emphasis. Here is _italic text_ for subtle emphasis. Here is ~~strikethrough text~~ for corrections or obsolete information. You can combine them freely: **_bold italic_**, **~~bold strikethrough~~**, _~~italic strikethrough~~_, and all three at once: **_~~bold italic strikethrough~~_**.

The shimmer shortcode applies a flowing color-wave effect to inline text: {{ <shimmer text="colorized.life" /> }}. It works alongside other formatting like **{{ <shimmer text="bold shimmer," /> }}** **_{{ <shimmer text="bold italics," /> }}_** and even **_~~{{ <shimmer text="bold italic strikethrough!!" /> }}~~_**

You can link to things like [the Zola documentation](https://www.getzola.org/documentation/) or to a project like [`pulldown-cmark`](https://github.com/raphlinus/pulldown-cmark), the Markdown parser Zola uses under the hood. Links should stand out from body text and respond to hover.

Emoji render natively without any special handling: 🦀 🎨 🔧 🚀 — useful for adding a bit of personality to posts without pulling in external assets.

# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

{{ <hr /> }}

Here is a `codeline` shortcode for single-line commands that need horizontal scroll on narrow screens:

{{ <codeline text="Long, single-line code blocks should not wrap. They should horizontally scroll if they are too long. This line should be long enough to demonstrate this." /> }}

> This is a blockquote. It can contain **bold**, _italic_, and `inline code` — all the usual inline formatting.
>
> It can also span multiple paragraphs.
>
> > And blockquotes can nest. This is a second level. Useful for quoting someone who is themselves quoting someone else.

Unordered list with three levels of nesting:

- Infrastructure
  - DNS resolver
  - Reverse proxy
    - TLS termination
    - Rate limiting
  - Monitoring stack
- Applications
  - Git forge
  - Blog engine
    - Zola with a custom theme

Ordered list:

1. Write the content in Markdown
2. Build the site with `zola build`
3. Deploy the output to the server
4. Verify everything renders correctly

Inline code like `prefix`, `count`, and `colorize()` should feel distinct from surrounding text — readable at a glance without breaking the flow of the sentence.

Here is a Rust snippet to test syntax highlighting against the site palette:

```rust
/// Colorize the given input with a prefix and count.
fn colorize(input: &str) -> String {
    let prefix = "vivid";
    let count = 42;
    format!("{prefix}:{input}:{count}")
}

fn main() {
    let result = colorize("hello");
    println!("{result}");
}
```

{{ <hr /> }}

## Tables

Tables support alignment and inline formatting:

| Feature    | Status     | Notes                       |
| ---------- | ---------- | --------------------------- |
| Markdown   | **Stable** | Full CommonMark support     |
| Shortcodes | **Stable** | `hr`, `codeline`, `ascii`   |
| Alerts     | **Stable** | All five GitHub alert types |
| Feed       | _Enabled_  | Atom via `generate_feeds`   |

Two-column variant:

| Shorthand | Expansion                |
| --------- | ------------------------ |
| `ufw`     | Uncomplicated Firewall   |
| `ssh`     | Secure Shell Protocol    |
| `tls`     | Transport Layer Security |
| `dns`     | Domain Name System       |

{{ <hr /> }}

## ASCII Art

The `ascii` shortcode renders preformatted box-drawing diagrams:

{% <ascii> %}
┌──────────────────────────────┐
│ Outer box                    │
│ ┌──────────────────────────┐ │
│ │ Inner box                │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
{% </ascii> %}

{{ <hr /> }}

## Images

The `image` shortcode renders a `<figure>` with lazy loading, optional positioning, and an auto-generated caption from the alt text. It supports both co-located assets and external URLs.

A full-width image with no position set:

{{ <image url="pastels_oil_pastels_colorful_1.jpg" alt="Oil pastels in every color of the spectrum" content_path={page.path} /> }}

The same image, floated left with body text wrapping around it:

{{ <image url="pastels_oil_pastels_colorful_1.jpg" position="left" alt="Oil pastels arranged in a vibrant rainbow" content_path={page.path} /> }}

When an image is positioned left, surrounding text flows naturally around it. This is useful for smaller illustrations or portraits that complement the text without dominating the layout. The text should wrap cleanly at any viewport width, and the image should never feel like it's colliding with the paragraph. Once enough text has accumulated, the flow returns to full width below the float.

And floated right:

{{ <image url="pastels_oil_pastels_colorful_1.jpg" position="right" alt="A close-up of colorful oil pastels" content_path={page.path} /> }}

Right-positioned images work the same way, just mirrored. Text wraps on the left side. This variant is handy for breaking up long runs of text with alternating visuals — left, then right — giving the page a more dynamic rhythm without resorting to a full-width image every time.

{{ <hr /> }}

## More Languages

Bash:

```bash
#!/usr/bin/env bash
set -euo pipefail

for f in *.md; do
    echo "Processing $f"
done
```

INI / config files:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <your-private-key>

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 10.0.0.2/32
```

Autolinks render bare URLs: <https://www.getzola.org/documentation/> and <https://github.com/getzola/zola>.

{{ <hr /> }}

## GitHub Alerts

> [!NOTE]
> Supplementary context that helps the reader understand the current topic without being critical to it.

> [!TIP]
> Practical advice the reader can act on — shortcuts, best practices, or alternative approaches.

> [!IMPORTANT]
> Key information the reader needs to know for things to work correctly. Don't skip this.

> [!WARNING]
> Something that could cause problems if ignored — unexpected behavior, common mistakes, or prerequisites.

> [!CAUTION]
> Potential for data loss, security issues, or irreversible actions. Proceed carefully.

{{ <hr /> }}

## Extra

### Color Utilities

The theme provides a set of color utility classes for inline use:

<span class="c-accent">`.c-accent` — the site's accent color</span><br>
<span class="c-pink">`.c-pink` — pink</span><br>
<span class="c-green">`.c-green` — green</span><br>
<span class="c-amber">`.c-amber` — amber</span><br>
<span class="c-blue">`.c-blue` — blue</span><br>
<span class="c-red">`.c-red` — red</span><br>
<span class="c-muted">`.c-muted` — muted/dimmed text</span>

### Icons

The theme ships a library of SVG icons as CSS custom properties. Each icon renders via a CSS mask on a colored `<span>`:

<span class="demo-icon" style="-webkit-mask-image:var(--icon-archive); mask-image:var(--icon-archive);"></span> `--icon-archive`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-bug); mask-image:var(--icon-bug);"></span> `--icon-bug`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-checkmark); mask-image:var(--icon-checkmark);"></span> `--icon-checkmark`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-copy); mask-image:var(--icon-copy);"></span> `--icon-copy`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-done); mask-image:var(--icon-done);"></span> `--icon-done`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-external); mask-image:var(--icon-external);"></span> `--icon-external`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-feed); mask-image:var(--icon-feed);"></span> `--icon-feed`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-fire); mask-image:var(--icon-fire);"></span> `--icon-fire`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-git); mask-image:var(--icon-git);"></span> `--icon-git`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-home); mask-image:var(--icon-home);"></span> `--icon-home`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-link); mask-image:var(--icon-link);"></span> `--icon-link`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-pencil); mask-image:var(--icon-pencil);"></span> `--icon-pencil`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-search); mask-image:var(--icon-search);"></span> `--icon-search`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-share); mask-image:var(--icon-share);"></span> `--icon-share`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-star); mask-image:var(--icon-star);"></span> `--icon-star`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-toc); mask-image:var(--icon-toc);"></span> `--icon-toc`
<span class="demo-icon" style="-webkit-mask-image:var(--icon-verified); mask-image:var(--icon-verified);"></span> `--icon-verified`
