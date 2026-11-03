---
name: build-brand-kit
description: >
  Build or refresh a business's brand kit in Marky from its website. Use this right
  after creating a new workspace, when generated posts look generic or off-brand, or
  whenever the user says "set up my brand", "pull my brand from my site", or gives you
  a URL and asks you to make Marky match it. Visits the site, extracts the logo, colors,
  fonts, voice, calls to action, and imagery style, shows the user the proposed kit for
  approval, then writes it into the workspace's two brand documents (design_style for
  the look, strategy for the voice) with the update_workspace MCP tool. Uses the
  marky-api skill for auth and the MCP connection. Also triggers on "my posts don't sound like me", "update my brand colors", "refresh my brand profile". For writing posts with the kit, see plan-social-content.
---

# Build Brand Kit

Turn the user's website into a complete brand kit in Marky, so every post Marky writes
or designs from then on sounds and looks like the business: right colors, right fonts,
right logo, right voice, instead of a generic default.

This is usually the **first thing worth doing after creating a workspace.** A thin or
empty brand kit is the number-one reason generated posts feel off. Ten minutes here
pays back on every post afterward.

**Read the `marky-api` skill first** for your `mk_live_` key and the MCP connection.
This skill drives Marky entirely through the **MCP tools** (`list_workspaces`,
`get_workspace`, `update_workspace`, `upload_media_from_url`, `create_media_upload`),
so no REST calls are needed.

## Where the kit lives: two documents

A workspace keeps its brand in two markdown documents. There are no separate color,
font, logo, tone or tagline fields any more (they left the API on 2026-11-03), so
everything below goes into one of these two. The rule: **words go to `strategy`,
visuals go to `design_style`.**

| Document | Holds | Size cap |
| :--- | :--- | :--- |
| `design_style` | How every post LOOKS: colours with exact hex codes (which leads, the accent), fonts and how type is set, the logo (its URL, background colour, where it sits, when it appears), imagery and whether stock photos are OK, whitespace, the content mix (designs, photos, carousels, video...) and the post shape (1:1, 4:5, 9:16). Then a `## Treatments` table of named looks. | 5,000 characters |
| `strategy` | What posts SAY and why: goal, audience, voice, calls to action, tagline, caption rules (including "Never ..." rules and the line every caption ends with), content pillars, what we won't do. | 6,000 characters |

**Both are replaced whole on every write.** `update_workspace(design_style=...)` swaps
the entire document, so always read the current one, edit it, and send all of it back.
Anything you leave out is deleted.

**The approval gate is mandatory.** These documents steer every future caption and
design, and they may already contain lines a teammate wrote on purpose. Never write
without showing the user exactly what will change, and never drop or rewrite an existing
line without calling that out.

## Stage 1: Read what's already there

1. Pick the workspace: `list_workspaces`, confirm with the user if there is more than one.
2. `get_workspace` and read `design_style`, `strategy`, `website` and `field_budgets`.
   Note what each document already covers (colours? fonts? logo? voice? CTAs?) and what
   is missing. `field_budgets` tells you how much room each document has left.
3. Get the source URL. Use the workspace's `website` if set; otherwise ask the user
   for their site (or, if they have no site, their most active social profile: the
   extraction below works on any page that carries their branding).

## Stage 2: Extract the brand from the website

Fetch the homepage plus one or two brand-dense pages (About, Services, a recent blog
post). Read both the rendered copy and the page source: the source is where the design
tokens live. Pull each ingredient:

**Logo.** Look, in order of quality: an SVG or PNG in the site header (its URL or class
usually contains "logo"), `apple-touch-icon`, `og:image` (only if it is actually the
logo, not a photo), the favicon as a last resort. Prefer an SVG or a transparent PNG at
240px+ wide. Download it and look at it: confirm it is the logo and note whether the
background is transparent or solid.

**Colors.** Find the palette the site actually uses, not every color on the page:

- CSS custom properties (`--primary`, `--brand`, `--accent` in `:root`) are the best
  source when present.
- Otherwise read the computed styles of the load-bearing elements: page background,
  headline text, primary buttons/links.
- The `theme-color` meta tag often names the primary.

Settle on **3 to 5 hex colors**: which one leads, the accent, the background and the
text colour. Skip near-duplicates and one-off decorative colors.

**Fonts.** Look for Google Fonts `<link>` tags or `@font-face` / `font-family`
declarations. Identify the **heading** family and the **body** family (often different).
Use Google Fonts family names; if the site uses a private/licensed font, pick the
closest Google Fonts match and tell the user you substituted.

**Voice.** Read the site's copy like an editor and describe the voice in 2 to 4 concrete
sentences: formality, warmth, sentence length, jargon or plain-spoken, emoji or not,
first person or third. Quote a line or two from the site as evidence. Also collect:

- **Tagline**: the hero headline or an explicit slogan, if there is one.
- **Calls to action**: the buttons and asks the site repeats ("Book a call", "Order online").
- **Verbatim phrases**: the exact wording the site repeats ("small-batch", "no
  contracts, ever"). Capture these word-for-word, not paraphrased: paraphrase is
  where a voice goes generic.
- **Anti-patterns**: what the brand clearly does NOT do (no emojis anywhere, never
  discounts, no exclamation marks). Negative rules prevent more off-brand output than
  positive ones; write them as explicit "Never ..." lines. If the user is present, ask
  directly: "Anything you never want said or shown?"
- **Closing line**: a link or hashtag block they want at the end of every caption, if any.

**Imagery style.** Look at the photos and graphics on the page and describe the pattern
in one or two sentences ("bright natural light, real staff and customers, warm tones,
no stock-looking shots"). Note whether stock photos would fit at all.

**Content mix and format.** If the user has a view (or their existing posts show one),
note the mix of formats they want (designed graphics, their own photos, carousels,
video) and the shape their posts are made at (1:1 square, 4:5 portrait, 9:16 vertical).

If the site is thin (a one-page placeholder, a parked domain), say so and fall back to
interviewing the user for the same ingredients instead of guessing. Offer two intake
paths and let them pick: a brain dump (they talk, you extract) or one question at a
time. Either way, keep their exact phrases: if they say "I hate the word synergy",
that sentence goes into the strategy's caption rules verbatim.

Note: the kit keeps improving after this skill runs. When the user edits your captions,
the style-critique protocol in the `marky-api` skill (brand-memory section) persists
what the edits reveal. Build the kit here; let use refine it.

## Stage 3: Draft both documents and get approval

Upload the logo first so the draft can carry its durable URL: if it's already at a URL,
`upload_media_from_url`; if it's a local file, `create_media_upload` then PUT the bytes
(pass a data URI, or raw base64 plus `content_type`). Use the returned media URL.
Hot-linking the site's own image URL is a last resort: sites move and break the logo
silently.

**`design_style`**: merge the look into the current document. The prose at the top is
binding on every image, so keep it to the things true of every post. A good shape:

```markdown
Lead colour is deep teal #0F4C5C on an off-white #F7F5F0 background; coral #E36414 is
the accent, used for one element per post at most. Text is charcoal #1F2421.
Headlines are set in Poppins SemiBold, tight and left-aligned; body text in Inter.
Logo: https://<media url from the upload>
The logo sits small in the top-left corner of every picture, on its transparent background.
Imagery is bright natural light with real staff and customers; no stock photos.
Generous whitespace, one idea per graphic.

## Content mix
Mostly designed graphics and their own photos; one carousel a week; no video yet.

## Format
Posts are 4:5 portrait.

## Treatments

| Treatment | What it is | How to build it |
| --- | --- | --- |
| Quote card | A customer's words, big | Off-white field, quote in teal Poppins, name small in coral underneath |
| Team photo | A real person at work | Their photo full-bleed, one short line in a teal band along the bottom |
```

Keep any existing Treatments rows the user chose. A row is one look; never repeat the
colours or fonts inside a row (they are already in the prose above it). Keep `## Treatments`
as the last section: the content mix and format sections go above it.

**`strategy`**: merge the words into the current document under these headings:
`## Voice`, `## Audience`, `## Calls to action` (the tagline goes here too) and
`## Caption rules` (verbatim phrases, "Never ..." lines, and the line every caption
ends with). Leave the
other sections (goal, pillars, experiments) exactly as they are.

Present both drafts with each change marked **KEEPING / ADDING / REPLACING**. Anything
marked REPLACING must show the current text next to the proposed one. Check the length
against `field_budgets`: if a draft is over the cap, tighten it before showing it.

Ask the user to approve, edit, or drop parts. Apply only what they approve. If both
documents were already complete and the user only wanted a refresh, an explicit
"replace the above" is still required.

## Stage 4: Write it to Marky

1. **One `update_workspace` call** carrying the approved `design_style` and/or `strategy`,
   each as the WHOLE document. Send only the documents that changed.
2. **Read the response.** If `warnings` has an entry for either document, it is over its
   size budget: rewrite it tighter now, while you still have it in context, and save again.
3. **Verify:** `get_workspace` again and confirm both documents round-tripped.
4. If you keep a local brand snapshot (`~/.marky/brand-cache.md` in a Claude Code plugin
   install: see the `marky-api` skill's brand-memory section), refresh it now so the
   next session starts on the new brand.

## Stage 5: Prove it

Don't end on a settings change; end on evidence. Offer to generate one draft post (the
`plan-social-content` or `schedule-posts` skill) or render one branded graphic
(`create-post-graphic`) so the user sees the new kit in action. If the result exposes a
bad extraction (muddy colours, wrong font weight), fix the document now while the
context is fresh.

**Marky wants your feedback.** If extraction hit friction or an `update_workspace` call
behaved unexpectedly, send a quick note via the `submit_feedback` MCP tool: see "Marky
wants your feedback" in the `marky-api` skill.
