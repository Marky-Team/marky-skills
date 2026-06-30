# Contributing to Marky Skills

Thanks for your interest in contributing! This repo is a collection of
[Agent Skills](https://agentskills.io) that teach coding agents how to drive
[Marky](https://app.mymarky.ai) — generate on-brand posts, schedule content, and
review performance through the Marky API and MCP server.

Every skill is plain Markdown (`SKILL.md`). There is no build step. If you can
write a good how-to, you can contribute a skill.

## Getting started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/marky-skills.git`
3. Create a branch: `git checkout -b my-skill`
4. Make your change and run the linter (below)

## Linting

```bash
npm run lint        # or: node scripts/lint-skills.mjs
```

The linter has no dependencies — it runs on plain Node 18+. It checks that:

- every `skills/<name>/SKILL.md` has valid frontmatter with a `name` and a `description`,
- the `name` matches the directory,
- no inline backtick contains shell-trap characters (`!`, or `>` before a word) that would stop Claude Code from loading the skill, and
- `skills-manifest.json` and `.claude-plugin/marketplace.json` register exactly the skills on disk.

CI runs the same check on every pull request.

## How a skill is structured

Each skill is one directory under `skills/`:

```
skills/<name>/
  SKILL.md          # required — the skill itself
  ...               # optional supporting files (scripts, references, examples)
```

### SKILL.md frontmatter spec

`SKILL.md` starts with a YAML frontmatter block:

```markdown
---
name: schedule-posts
description: >
  Create, upload media to, and schedule social media posts through the Marky API.
  Use this when you have post content ready and want it on your connected
  accounts on a schedule. Reads auth and endpoint details from the marky-api skill.
---

# Schedule posts

...the skill body in Markdown...
```

| Field | Required | Rules |
| :--- | :--- | :--- |
| `name` | Yes | Must exactly match the directory name. Lowercase, hyphenated. |
| `description` | Yes | One paragraph. Lead with **what job it gets done** and **when to use it** — this is what an agent reads to decide whether to load the skill. A block scalar (`>`) keeps it readable. |

Write the **body** as a clear, step-by-step guide an agent can follow: which
endpoints to call, in what order, with example requests and responses. Keep
commands in fenced code blocks (the linter rejects shell-trap characters in
inline backticks). The `marky-api` skill holds the shared auth + base-URL +
endpoint reference; other skills should point to it rather than repeat it.

## Quality bar

Before opening a PR, a skill should clear this bar:

- **Real job, plainly named.** It gets one social-media job done and says so in the first sentence of the description.
- **Self-contained or clearly delegated.** It either explains the full flow or explicitly defers to `marky-api` for auth and endpoints.
- **Tested with a real agent.** You ran it in Claude Code (or another agent) end to end and it worked against the live Marky API.
- **Genericized.** No real API keys, business IDs, internal hostnames, or company-internal references. Use placeholders like `mk_live_YOUR_KEY` and `BIZ_ID`.
- **Lints clean.** `npm run lint` passes.

## Adding a new skill — checklist

1. Create `skills/<name>/SKILL.md` with valid frontmatter (see the spec above).
2. Register the skill in **both** manifests:
   - add an entry under `skills` in `skills-manifest.json`
   - add `"./skills/<name>"` to the `skills` array in `.claude-plugin/marketplace.json` (and `.claude-plugin/plugin.json`)
3. Add a row to the skill catalog table in `README.md`.
4. Run `npm run lint` until it passes.
5. Test the install flow: `npx skills add marky-team/marky-skills --skill <name>`.
6. Open a PR using the template.

> The `hash` in `skills-manifest.json` is a content fingerprint used by
> `npx skills` to detect when an installed skill is stale. If you have the
> `skills` CLI, let it regenerate the manifest; otherwise a maintainer will
> refresh the hash on merge. The lint check only enforces that the skill is
> *registered*, not the exact hash value.

## Pull requests

- Keep PRs focused — one skill or one coherent change.
- CI must pass before merge.
- Describe what the skill does and how you tested it (the PR template prompts for this).

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold it.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
