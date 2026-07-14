# Marky — agent install guide

You are an AI agent installing Marky's skills for your user. Marky is a social media
manager: it writes, designs, schedules, and publishes posts. These skills teach you to
drive it. Follow the steps for YOUR client type, top to bottom. Ask the user only for
what the steps say to ask.

## 1. Detect your client and install the skills

**Claude Code** — install the plugin (skills + session hooks + `/marky` command + the
MCP server config, all in one):

```
claude plugin marketplace add Marky-Team/marky-skills
claude plugin install marky@marky-skills
```

If those CLI commands are unavailable, tell the user to type `/plugin marketplace add
Marky-Team/marky-skills` and then `/plugin install marky@marky-skills` in their next
prompt.

Then have the user **sign in**: they type `/mcp`, pick **marky**, choose
**Authenticate** — their browser opens Marky's page, they click Allow and pick their
organization. That is the whole auth setup: **no API key needed.**

**Claude Cowork / Desktop** — you cannot install this yourself; give the user these
two UI steps: (1) Customize -> Plugins -> Add -> Add marketplace -> Add from a
repository -> `Marky-Team/marky-skills`, then **Add** the Marky plugin. (2) Installing
the plugin surfaces the **Marky connector (MCP)** — click **Connect**; their browser
opens Marky's sign-in page, they click Allow and pick their organization. **No API key
is needed on these surfaces** — skip steps 2 and 3.

**Codex, Cursor, Windsurf, or any other agent that supports Agent Skills:**

```bash
npx skills add marky-team/marky-skills -g
```

Then connect the MCP with OAuth — `mcp-remote` runs the sign-in (browser opens,
the user clicks Allow and picks their organization). Codex
(`~/.codex/config.toml`):

```toml
[mcp_servers.marky]
command = "npx"
args = ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp"]
```

Other MCP clients take the same shape:

```json
{
  "mcpServers": {
    "marky": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp"]
    }
  }
}
```

(`-g` installs user-level so Marky works from any directory, which is what you want for
"run my social media from wherever I'm working".)

## 2. Verify

Call the `list_businesses` MCP tool. Seeing the user's workspaces = installed
correctly. Tell the user it worked and show them their business names.

If it fails: "needs authentication" means the user hasn't finished the OAuth sign-in
yet — have them authenticate and retry; anything else, read the `marky-api` skill's
troubleshooting notes.

## 3. Show the user what they can do now

Offer a few of these first prompts:

- "Plan a week of posts for my business. Ask me what's coming up first."
- "What were my top posts last month? Repurpose the best one."
- "Suggest 10 topics my audience would love."
- "Make a countdown series for my event on [date]."
- "Schedule my drafts across next week."

Before doing real work, read the `marky-api` skill — it is the contract every other
Marky skill builds on (auth, endpoints, the curated MCP tools, session-start checks).
