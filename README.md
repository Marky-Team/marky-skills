# Marky Skills

Agent skills that give Claude the tools to manage your social media with
[Marky](https://app.mymarky.ai). Install them into Claude Code, Claude Desktop, Cursor, or
any agent that supports the [Agent Skills](https://agentskills.io) format, then drive your
whole social workflow in plain language: generate on-brand posts, upload media, schedule a
week of content, and check what published.

Marky is the API- and MCP-driven social tool. These skills are the cheat sheet that lets
Claude use it well.

## Install

```bash
npx skills add marky-team/marky-skills
```

That installs all three skills. To install just one:

```bash
npx skills add marky-team/marky-skills --skill marky-api
npx skills add marky-team/marky-skills --skill plan-social-content
npx skills add marky-team/marky-skills --skill schedule-posts
```

The installer auto-detects your agent (Claude Code, Claude Desktop, Cursor, and many more)
and drops the skills in the right place.

## The skills

| Skill | What it is |
| :--- | :--- |
| **marky-api** | Reference skill: authenticate, the base URL, the key endpoints, and how to connect Marky's MCP server to Claude Code and Claude Desktop / Cowork. Start here. |
| **schedule-posts** | Use-case skill: upload media, create or generate posts, schedule them, and confirm they published. |
| **plan-social-content** | Use-case skill: plan, write, and schedule a full week of on-brand content. Mines your real material, drafts in your voice, and always gets your approval before scheduling. |

## Quickstart

1. **Get a key.** Sign in at [app.mymarky.ai](https://app.mymarky.ai), open
   **Organization Settings -> API Keys**, click **Create API Key**, and copy the
   `mk_live_...` value (shown once).

2. **Connect Marky's MCP** so Claude can use Marky's tools natively.

   Claude Code CLI:

   ```bash
   claude mcp add --transport http marky https://api.mymarky.ai/api/mcp \
     --header "Authorization: Bearer mk_live_YOUR_KEY"
   ```

   Claude Desktop / Cowork: add this to your `claude_desktop_config.json` and restart:

   ```json
   {
     "mcpServers": {
       "marky": {
         "command": "npx",
         "args": ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp",
                  "--header", "Authorization: Bearer mk_live_YOUR_KEY"]
       }
     }
   }
   ```

   (Full instructions, including the REST option, are in the `marky-api` skill.)

3. **First post.** Connect a social account in the Marky dashboard first (the API can see
   accounts but cannot add them), then ask Claude:

   > "List my Marky businesses, generate 3 posts about our new spring blend, and schedule
   > one each morning this week."

## Requirements

- A [Marky](https://app.mymarky.ai) account with at least one connected social account.
- An API key (`mk_live_...`) — see step 1.
- An agent that supports Agent Skills (Claude Code, Claude Desktop, Cursor, ...).

## Links

- Marky app: https://app.mymarky.ai
- API docs: https://docs.mymarky.ai
- Questions: support@mymarky.ai

## License

MIT. See [LICENSE](./LICENSE).
