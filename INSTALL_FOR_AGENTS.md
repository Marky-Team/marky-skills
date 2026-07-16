# Marky — agent install guide

You are an AI agent installing Marky for your user. Marky is a social media manager:
it writes, designs, schedules, and publishes posts. Pick YOUR client below, do that
one step, then finish with "After connecting".

**Claude Code?**

```
/plugin marketplace add Marky-Team/marky-skills
/plugin install marky@marky-skills
```

Then the user signs in: `/mcp` → **marky** → **Authenticate** (browser opens, they
click Allow).

**Claude Cowork / Desktop?**

You can't install this yourself — send the user the 4-minute video:
https://github.com/Marky-Team/marky-skills/blob/main/README.md
(Customize → Plugins → add the `Marky-Team/marky-skills` marketplace → add the Marky
plugin → **Connect** on the Marky connector → **Allow**.)

**Other agent (Codex, Cursor, ...)?**

Install the skills:

```bash
npx skills add marky-team/marky-skills -g
```

Install the MCP — `mcp-remote` signs the user in (browser opens, they click Allow).
Codex (`~/.codex/config.toml`):

```toml
[mcp_servers.marky]
command = "npx"
args = ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp"]
```

## After connecting

Call the `list_businesses` MCP tool and ask your user which business they want to
work on first — remember that preference (the `marky-api` skill's `user.toml` covers
where).

**Empty list (brand-new account)?** Bootstrap it: run `/build-brand-kit` with their
website (or `create_business` if they have no site), then send them to
`https://app.mymarky.ai/ws/{business_id}/business/profile` to connect their social
accounts — that page is where Instagram/Facebook/LinkedIn/TikTok get linked, and
publishing can't work until at least one is. Content creation works right away.

Then offer a few ideas of what to do next:

- "/plan-social-content for my business. Ask me what's coming up first."
- "/review-performance — what were my top posts last month? Repurpose the best one."
- "/suggest-topics my audience would love."
- "/build-brand-kit from my website."
