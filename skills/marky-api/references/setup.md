# Setup: get an API key and connect the MCP

Part of the `marky-api` skill. Read this when the user needs to CREATE an API key,
PERSIST it, or CONNECT Marky's MCP server to a client (Claude Code, Cowork, Codex,
Cursor, custom agents). For day-to-day calls you don't need this file — the base URL,
auth header, and endpoints are in the main SKILL.md.

## Get your API key

1. Sign in at [app.mymarky.ai](https://app.mymarky.ai).
2. Open **Organization Settings -> API Keys** (left sidebar -> Settings, then scroll to
   API Keys).
3. Click **Create API Key**, name it, and copy the `mk_live_...` value. It is only shown
   once, so save it somewhere safe.
4. **If you use this plugin in Claude Code**, put the key in the `MARKY_API_KEY`
   environment variable (the bundled MCP server reads it). Persist it — a bare
   `export` lasts only until the terminal closes. Pick one:

   - **Recommended:** add it to Claude Code's own settings so it works no matter how
     Claude Code is launched (terminal, desktop app, IDE). In `~/.claude/settings.json`:

     ```json
     { "env": { "MARKY_API_KEY": "mk_live_YOUR_KEY" } }
     ```

     (Merge into the existing file if it already has other keys.)

   - Or add the export to your shell profile (`~/.zshrc` for zsh, `~/.bashrc` for bash):

     ```bash
     echo 'export MARKY_API_KEY="mk_live_YOUR_KEY"' >> ~/.zshrc
     ```

     Note: GUI-launched apps do not read your shell profile, so prefer the
     settings.json option if you use the Claude desktop app or an IDE.

Notes:
- You must be an **org admin** to create keys.
- A key has access to every workspace (business) in your organization.
- Keep the key in an environment variable or `.env` file, never in source control.
- Each org can have up to 10 active keys. Revoke a leaked key from the same page.

## Connect the MCP

The Marky MCP server lets an agent call Marky's tools directly instead of you pasting REST
instructions.

```
MCP endpoint:  https://api.mymarky.ai/api/mcp
Transport:     streamable HTTP
Auth:          Authorization: Bearer mk_live_YOUR_KEY
```

### Claude Code CLI

**If you installed this plugin, the MCP server is already bundled** (in the plugin's
`.mcp.json`) — you only need your key in the `MARKY_API_KEY` environment variable.
Persist it in `~/.claude/settings.json` (or your shell profile) — see "Get your API
key" above for both options; a one-off `export` disappears when the terminal closes:

```json
{ "env": { "MARKY_API_KEY": "mk_live_YOUR_KEY" } }
```

Then ask: *"List my Marky businesses."* Claude calls `list_businesses` and shows your
workspaces. Each has an `id` you use as `business_id` for everything else.

**Not using the plugin?** Register the server manually (replace `mk_live_YOUR_KEY`):

```bash
claude mcp add --transport http marky https://api.mymarky.ai/api/mcp \
  --header "Authorization: Bearer mk_live_YOUR_KEY"
```

### Cowork

Cowork adds remote MCP servers as **custom connectors** in the UI — even with the Marky
plugin installed, the connector is a separate manual step (the plugin carries skills,
hooks, and the `/marky` command; Cowork does not read the plugin's `.mcp.json`):

1. **Settings → Connectors → Add → Add custom connector**
2. Name: `Marky`; URL: `https://api.mymarky.ai/api/mcp`
3. Leave the OAuth Client ID/Secret fields blank, click **Add**, and paste your
   `mk_live_...` key when asked for the API key / bearer token.

Marky's tools then appear in the tools menu for every Cowork session.

### Codex CLI

Codex talks to local (stdio) MCP servers, so bridge to Marky's remote HTTP server with the
open-source `mcp-remote` package (run on demand via `npx`, no install). Add to
`~/.codex/config.toml`:

```toml
[mcp_servers.marky]
command = "npx"
args = ["-y", "mcp-remote", "https://api.mymarky.ai/api/mcp", "--header", "Authorization:${MARKY_AUTH}"]
env = { "MARKY_AUTH" = "Bearer mk_live_YOUR_KEY" }
```

(The key sits in the `env` block on purpose, so the space in `Bearer mk_live_...` is
passed as one piece and not split apart.)

### Any other MCP client (Cursor, custom agents)

Most clients take a config like this:

```json
{
  "mcpServers": {
    "marky": {
      "transport": "http",
      "url": "https://api.mymarky.ai/api/mcp",
      "headers": { "Authorization": "Bearer mk_live_YOUR_KEY" }
    }
  }
}
```
