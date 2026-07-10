---
name: build-brand-kit
description: >
  Build or refresh a business's brand kit in Marky from its website. Use this right
  after connecting a new business, when generated posts look generic or off-brand, or
  whenever the user says "set up my brand", "pull my brand from my site", or gives you
  a URL and asks you to make Marky match it. Visits the site, extracts the logo, colors,
  fonts, voice, tagline, and imagery style, shows the user the proposed kit for approval,
  then writes it to the business with the update_business MCP tool. Uses the marky-api
  skill for auth and the MCP connection.
---

# Build Brand Kit

Turn the user's website into a complete brand profile in Marky, so every post Marky
writes or designs from then on sounds and looks like the business — right colors, right
fonts, right logo, right voice — instead of a generic default.

This is usually the **first thing worth doing after connecting a business.** A thin or
empty brand profile is the number-one reason generated posts feel off. Ten minutes here
pays back on every post afterward.

**Read the `marky-api` skill first** for your `mk_live_` key and the MCP connection.
This skill drives Marky entirely through the **MCP tools** (`list_businesses`,
`get_business`, `update_business`, `upload_media_base64`) — every step below has a tool,
so no REST calls are needed.

**The approval gate is mandatory.** The brand profile steers every future caption and
design, and it may already contain values a teammate set on purpose. Never write to it
without showing the user exactly what you are about to set — and never overwrite an
existing non-empty field without calling that out specifically.

## Stage 1 — Read what's already there

1. Pick the business: `list_businesses`, confirm with the user if there is more than one.
2. `get_business` and note, field by field, what is **empty** versus **already set**:
   `tone`, `tagline`, `ctas`, `caption_writing_rules`, `imagery_preferences`, `palettes`,
   `header_font`, `body_font`, `logo_url`, `logo_background_color`.
3. Get the source URL. Use the business's `website_url` if set; otherwise ask the user
   for their site (or, if they have no site, their most active social profile — the
   extraction below works on any page that carries their branding).

## Stage 2 — Extract the brand from the website

Fetch the homepage plus one or two brand-dense pages (About, Services, a recent blog
post). Read both the rendered copy and the page source — the source is where the design
tokens live. Pull each ingredient:

**Logo.** Look, in order of quality: an SVG or PNG in the site header (its URL or class
usually contains "logo"), `apple-touch-icon`, `og:image` (only if it is actually the
logo, not a photo), the favicon as a last resort. Prefer an SVG or a transparent PNG at
240px+ wide. Download it and look at it — confirm it is the logo and note whether the
background is transparent or solid (you need this for `logo_background_color`).

**Colors.** Find the palette the site actually uses, not every color on the page:

- CSS custom properties (`--primary`, `--brand`, `--accent` in `:root`) are the best
  source when present.
- Otherwise read the computed styles of the load-bearing elements: page background,
  headline text, primary buttons/links.
- The `theme-color` meta tag often names the primary.

Build **one palette of 3–5 hex colors** ordered roughly background → text → accent(s).
Skip near-duplicates and one-off decorative colors.

**Fonts.** Look for Google Fonts `<link>` tags or `@font-face` / `font-family`
declarations. Identify the **heading** family and the **body** family (often different).
Marky renders Google Fonts families by name — if the site uses a private/licensed font,
pick the closest Google Fonts match and tell the user you substituted.

**Voice.** Read the site's copy like an editor and describe the voice in 2–4 concrete
sentences: formality, warmth, sentence length, jargon or plain-spoken, emoji or not,
first person or third. Quote a line or two from the site as evidence. Also collect:

- **Tagline** — the hero headline or an explicit slogan, if there is one.
- **CTAs** — the buttons and asks the site repeats ("Book a call", "Order online").
- **Words they use / avoid** — recurring vocabulary worth keeping (goes into
  `caption_writing_rules` only if clear and consistent).

**Imagery style.** Look at the photos and graphics on the page and describe the pattern
in one or two sentences ("bright natural light, real staff and customers, warm tones —
no stock-looking shots"). This becomes `imagery_preferences`.

If the site is thin (a one-page placeholder, a parked domain), say so and fall back to
interviewing the user for the same ingredients instead of guessing.

## Stage 3 — Show the kit and get approval

Present the proposed kit in one compact block: each field, its proposed value, and —
critically — a **KEEPING / SETTING / REPLACING** marker per field. Anything marked
REPLACING must show the current value next to the proposed one. Render the palette as
hex codes and describe the logo (file, size, transparent or not).

Ask the user to approve, edit, or drop fields. Apply only what they approve. If every
field was already set and the user only wanted a refresh, an explicit "replace all of
the above" is still required.

## Stage 4 — Write it to Marky

1. **Upload the logo** with the `upload_media_base64` MCP tool (pass a data URI, or raw
   base64 plus `content_type`). Use the returned media URL as `logo_url`. Hot-linking
   the site's own image URL is a last resort — sites move and break the logo silently.
2. **One `update_business` call** with only the approved fields. Shape notes that bite:
   - `palettes` is a list of palette **objects**: 
     `[{"name": "Brand", "colors": ["#101418", "#FFFFFF", "#E11D48"]}]` — colors live at
     `palettes[0].colors`, not a bare nested array.
   - `header_font` / `body_font` are objects: `{"family": "Poppins"}`.
   - `logo_background_color` — `"#00000000"` for a transparent logo, otherwise the solid
     color the logo needs behind it.
3. **Verify:** `get_business` again and confirm every approved field round-tripped.
4. If you keep a local brand snapshot (`~/.marky/brand-cache.md` in a Claude Code plugin
   install — see the `marky-api` skill's brand-memory section), refresh it now so the
   next session starts on the new brand.

## Stage 5 — Prove it

Don't end on a settings change; end on evidence. Offer to generate one draft post (the
`plan-social-content` or `schedule-posts` skill) or render one branded diagram
(`create-post-graphic`) so the user sees the new kit in action. If the result exposes a
bad extraction (muddy palette, wrong font weight), fix the profile now while the context
is fresh.

**Marky wants your feedback.** If extraction hit friction or an `update_business` field
behaved unexpectedly, send a quick note via the `submit_feedback` MCP tool — see "Marky
wants your feedback" in the `marky-api` skill.
