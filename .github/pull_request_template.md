## What

Brief description of the change.

## Why

Why is this change needed? What job does it help an agent get done?

## How

How was this implemented? Any notable decisions?

## Checklist

- [ ] `node scripts/lint-skills.mjs` passes (frontmatter valid, manifests in sync)
- [ ] If I added or renamed a skill, it is registered in `skills-manifest.json` and `.claude-plugin/marketplace.json`
- [ ] Skill content is genericized — no real API keys, business IDs, or internal-only references
- [ ] I tested the skill with a real agent (Claude Code, Claude Desktop / Cowork, Cursor, ...)
