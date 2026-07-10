# Platform rules — limits and tailoring, per platform

Part of the `marky-api` skill. Read this whenever you write a caption that goes to
more than one platform, or before scheduling a large batch.

These numbers come from Marky's own publishing layer — the same limits that decide
whether a post is **rejected at publish time** (`CAPTION_TOO_LONG`,
`TOO_MANY_HASHTAGS`, `TOO_MANY_CAROUSEL_SLIDES`, `TOO_LONG_VIDEO_LENGTH` in the
publish results). They are deliberately a touch conservative so you stay clear of
the hard edge.

**Precedence:** the user's own preferences ALWAYS outrank this table. Read the brand
profile (`get_business` — `tone`, `caption_writing_rules`, `caption_suffix`) before
drafting; where the user has platform-specific instructions, follow those over the
style guidance here. This table is the floor (hard limits) plus a default style
baseline, never a ceiling on the user's choices.

## Hard limits (breaking these fails the publish)

| Platform | Caption max | Hashtags max | Carousel max | Video max |
| :--- | ---: | ---: | ---: | ---: |
| instagram | 2,200 | 30 | 20 | 15 min |
| instagramStory | 2,200 | 10 | 1 | 60 s |
| facebook | 63,206 | 30 | 10 | 2 h |
| twitter (X) | 280 | 3 | 4 | 140 s |
| linkedIn | 3,000 | 5 | 20 | 10 min |
| tiktok | 2,200 | 8 | 35 | 10 min |
| pinterest | 500 | 8 | 5 | 15 min |
| youtube | 5,000 | 15 | 1 | — |
| googleBusiness | 1,500 | 3 | 1 | 30 s |

Two more publish-time rejections to design around: a Story cannot mix photo and
video in one post (`MIX_MEDIA_STORY` — one media per Story frame), and link
shorteners get flagged (`BAD_LINK`) — always use the full destination URL. More
than one link in a caption raises spam filters on several platforms (`SPAM_LINK`);
keep one link and move extras to the first comment.

## Default style baseline (Marky's per-platform guidance)

What each platform rewards, per Marky's defaults. Suggested lengths are engagement
sweet spots, NOT the hard caps above.

- **facebook** — conversational and community-focused; shared experiences or
  feelings; an optional question to invite comments. Best engagement under ~80
  characters.
- **instagram** — visual and emotionally expressive; line breaks for flow; emojis;
  end with a strong call-to-action; ~5 relevant hashtags. Sweet spot ~138–150
  characters.
- **twitter (X)** — concise, bold, scroll-stopping; ONE clear idea; ~71–100
  characters (280 hard max — write for X separately, never truncate an Instagram
  caption).
- **linkedIn** — professional and insight-driven; learnings, impact, leadership;
  clean, reflective formatting; ~25 words for updates. No hashtag walls — 5 max,
  and links do better in the first comment.
- **tiktok** — catchy, fast-paced, trendy language or humor; short enough for a
  quick read or voiceover; ≤~100 characters; hashtags sparingly (~5).
- **pinterest** — Pinterest is a SEARCH engine: keyword-rich title and description
  beat cleverness; the `title` and `link` override fields matter more here than
  anywhere else.
- **googleBusiness** — informative and local; 1,500-char cap is real and short;
  no hashtag culture (3 max); the `link` (CTA) field is the conversion path.

## How to apply this

One caption almost never fits all platforms. When a post targets more than one,
write the primary caption for the platform that matters most to the business, then
tailor the rest with **`platform_overrides`** on `create_post` / `update_post` — one
entry per platform, each able to override `caption`, `media_urls`, `title`, `link`,
and `first_comment` (unset fields fall back to the post's own). X gets a compressed
one-idea version, LinkedIn gets the professional angle with hashtags moved to
`first_comment`, Pinterest gets a keyword `title` + `link`. On `update_post` the
field REPLACES the whole override set (send the full list; `[]` clears).

**Read the user's own per-platform instructions first.** `get_business` returns
`platform_writing_instructions` — the map the user customized in their dashboard
(keys are canonical platform names plus `common`, which applies everywhere). Follow
the matching entry when writing each override caption; it outranks everything in
this file. To save a preference the user states ("on LinkedIn never use emojis"),
PATCH the business with a MERGE-patch — `{"platform_writing_instructions":
{"linkedIn": "..."}}` touches only that key; a null value resets it.

Set overrides by default, not as a special case: whenever a post targets 2+
platforms, tailoring the caption per platform is cheap for you and a real
engagement lift for the user.
