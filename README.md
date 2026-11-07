# SketchUp MCP

Local MCP integration for connecting Claude Code and Codex to SketchUp 2024 on
Windows and macOS.

## Project status

Phases 0 through 5 are implemented at the initial vertical-slice level.
SketchUp runtime testing and platform packaging validation are still pending.
The agreed architecture is:

```text
Claude Code / Codex
        |
        | MCP over stdio
        v
TypeScript MCP server
        |
        | Authenticated loopback TCP with newline-delimited JSON
        v
SketchUp Ruby extension
        |
        v
SketchUp Ruby API
```

The bridge will:

- Start automatically when the extension loads.
- Support one active SketchUp instance per MCP server.
- Bind to `127.0.0.1`.
- Use a per-user token stored outside the repository.
- Exchange protocol version 1 messages.
- Use explicit `{ "value": number, "unit": "..." }` dimensions.
- Require preview and explicit execution for destructive operations.
- Never execute arbitrary Ruby received from an AI client.

## Local development documentation

The `docs/` directory is intentionally ignored by Git because it contains
local development planning and working documentation. It remains available in
this workspace but is not part of the repository's committed distribution.

Use the committed [README installation section](#install-and-connect) for the
current setup instructions.

## Install and connect

The integration has two processes:

1. The SketchUp extension runs inside SketchUp and opens an authenticated local
   bridge on `127.0.0.1:43821`.
2. The TypeScript MCP server is started by Claude Code, Claude Desktop, or
   another MCP client over stdio.

SketchUp must be running before the MCP tools can inspect or change a model.

### Requirements

All platforms require:

- SketchUp 2024.
- Node.js 20 LTS or newer compatible LTS.
- npm, included with Node.js.
- Git, if installing from the repository.

Ruby is not required separately to run the extension; SketchUp supplies its
embedded Ruby runtime. Standalone Ruby is useful only for syntax checks.

### Windows installation

#### 1. Get the repository

```powershell
git clone <REPOSITORY_URL> C:\File\SketchUP
Set-Location C:\File\SketchUP
```

If the repository is already present, update it instead:

```powershell
Set-Location C:\File\SketchUP
git pull
```

#### 2. Build and install the SketchUp extension

```powershell
.\scripts\package-extension.ps1
```

This creates:

```text
C:\File\SketchUP\dist\sketchup-mcp-0.1.0.rbz
```

In SketchUp:

1. Open **Window > Extension Manager**.
2. Select **Install Extension**.
3. Choose `C:\File\SketchUP\dist\sketchup-mcp-0.1.0.rbz`.
4. Accept the extension prompt.
5. Open or create a model.

The extension creates its token at:

```text
%APPDATA%\SketchUpMcp\bridge.token
```

#### 3. Build the MCP server

```powershell
Set-Location C:\File\SketchUP\mcp-server
npm install
npm run build
```

Verify the compiled entry point exists:

```powershell
Test-Path C:\File\SketchUP\mcp-server\dist\index.js
```

#### 4. Test the token

```powershell
$token = (Get-Content "$env:APPDATA\SketchUpMcp\bridge.token" -Raw).Trim()
if ($token.Length -lt 16) { throw "Bridge token is missing or invalid" }
$env:SKETCHUP_BRIDGE_TOKEN = $token
```

Do not commit this token or paste it into chat.

### macOS installation

#### 1. Get the repository

```sh
git clone <REPOSITORY_URL> "$HOME/SketchUP"
cd "$HOME/SketchUP"
```

For an existing checkout:

```sh
cd "$HOME/SketchUP"
git pull
```

#### 2. Build and install the SketchUp extension

```sh
./scripts/package-extension.sh
```

If the script is not executable:

```sh
chmod +x ./scripts/package-extension.sh
./scripts/package-extension.sh
```

This creates:

```text
$HOME/SketchUP/dist/sketchup-mcp-0.1.0.rbz
```

In SketchUp:

1. Open **Extensions > Extension Manager**.
2. Select **Install Extension**.
3. Choose `$HOME/SketchUP/dist/sketchup-mcp-0.1.0.rbz`.
4. Accept the extension prompt.
5. Open or create a model.

The extension creates its token at:

```text
$HOME/SketchUpMcp/bridge.token
```

#### 3. Build the MCP server

```sh
cd "$HOME/SketchUP/mcp-server"
npm install
npm run build
test -f "$HOME/SketchUP/mcp-server/dist/index.js"
```

#### 4. Test the token

```sh
export SKETCHUP_BRIDGE_TOKEN="$(tr -d '\n' < "$HOME/SketchUpMcp/bridge.token")"
test "${#SKETCHUP_BRIDGE_TOKEN}" -ge 16
```

Do not commit this token or paste it into chat.

### Connect Claude Code

Claude Code starts the MCP server as a local stdio process. Register it with
the CLI after building the server and loading the SketchUp extension.

Windows PowerShell:

```powershell
$token = (Get-Content "$env:APPDATA\SketchUpMcp\bridge.token" -Raw).Trim()
claude mcp add --transport stdio `
  --env "SKETCHUP_BRIDGE_TOKEN=$token" `
  sketchup -- `
  node "C:\File\SketchUP\mcp-server\dist\index.js"
```

macOS:

```sh
token="$(tr -d '\n' < "$HOME/SketchUpMcp/bridge.token")"
claude mcp add --transport stdio \
  --env "SKETCHUP_BRIDGE_TOKEN=$token" \
  sketchup -- \
  node "$HOME/SketchUP/mcp-server/dist/index.js"
```

Verify registration:

```sh
claude mcp list
```

Start Claude Code from the repository and test:

```text
Check the SketchUp connection and return the model summary.
```

### Connect Claude Desktop

In Claude Desktop, open **Settings > Developer > Edit Config**. Add the
`sketchup` entry inside the existing `mcpServers` object.

Windows file:

```text
%APPDATA%\Claude\claude_desktop_config.json
```

Windows entry:

```json
{
  "mcpServers": {
    "sketchup": {
      "command": "node",
      "args": ["C:\\File\\SketchUP\\mcp-server\\dist\\index.js"],
      "env": {
        "SKETCHUP_BRIDGE_TOKEN": "PASTE_TOKEN_FROM_%APPDATA%_HERE"
      }
    }
  }
}
```

macOS file:

```text
~/Library/Application Support/Claude/claude_desktop_config.json
```

macOS entry:

```json
{
  "mcpServers": {
    "sketchup": {
      "command": "node",
      "args": ["/Users/YOUR_USER/SketchUP/mcp-server/dist/index.js"],
      "env": {
        "SKETCHUP_BRIDGE_TOKEN": "PASTE_TOKEN_FROM_~/SketchUpMcp_HERE"
      }
    }
  }
}
```

Replace the placeholder with the token value from the local token file. Do not
use a committed config file containing the token. Preserve any other existing
`mcpServers` entries.

After saving:

1. Completely quit Claude Desktop.
2. Start Claude Desktop again.
3. Keep SketchUp open with the extension loaded.
4. Ask Claude for the SketchUp model summary.

### Optional manual MCP server test

The MCP server normally receives stdio input from the client. To check startup
configuration without a client:

Windows:

```powershell
$env:SKETCHUP_BRIDGE_TOKEN = (Get-Content "$env:APPDATA\SketchUpMcp\bridge.token" -Raw).Trim()
node C:\File\SketchUP\mcp-server\dist\index.js
```

macOS:

```sh
export SKETCHUP_BRIDGE_TOKEN="$(tr -d '\n' < "$HOME/SketchUpMcp/bridge.token")"
node "$HOME/SketchUP/mcp-server/dist/index.js"
```

The process may wait for MCP stdio input. Stop it with `Ctrl+C`.

### Troubleshooting

#### Connection refused

- Confirm SketchUp is open.
- Confirm the extension is enabled in Extension Manager.
- Confirm a model is open.
- Confirm the MCP server uses the same token generated by the extension.
- Confirm no other process is using TCP port `43821`.

#### Claude Desktop does not show the server

- Validate the JSON configuration.
- Use an absolute path in `args`.
- Confirm `node` is available to Claude Desktop.
- Preserve the outer `mcpServers` object and existing entries.
- Completely quit and restart Claude Desktop.
- Review Claude Desktop MCP logs.

#### Claude Code registration fails

- Run `claude mcp list`.
- Confirm `--` appears before `node`.
- Confirm the token contains at least 16 characters.
- Use the absolute path to `dist/index.js`.

#### Reset the token

1. Close SketchUp.
2. Remove only the token file:
   - Windows: `%APPDATA%\SketchUpMcp\bridge.token`
   - macOS: `$HOME/SketchUpMcp/bridge.token`
3. Restart SketchUp with the extension enabled.
4. Re-register or update the MCP client with the new token.

## Agent Skills

Canonical Skills are stored under [skills](skills) and synchronized into the
client-specific directories [.github/skills](.github/skills),
[.claude/skills](.claude/skills), and [.agents/skills](.agents/skills) so VS
Code/Copilot, Claude Code, and Codex can discover them automatically. Their
descriptions are keyword-rich so each agent can select the most specific Skill:

- [sketchup-modeling](skills/sketchup-modeling/SKILL.md) for geometry and
  model changes
- [sketchup-model-inspection](skills/sketchup-model-inspection/SKILL.md)
  for read-only model questions
- [sketchup-automation](skills/sketchup-automation/SKILL.md) for
  repeatable and batch workflows
- [sketchup-quality-check](skills/sketchup-quality-check/SKILL.md) for
  audits and validation reports

The routing rules are in [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), and
[.github/copilot-instructions.md](.github/copilot-instructions.md). See
[docs/skills.md](docs/skills.md) for the synchronization workflow.
- [Protocol message schema](protocol/messages.schema.json)
- [Protocol operation schema](protocol/operations.schema.json)

## Next step

Next, validate the extension inside SketchUp 2024 on Windows and macOS, then
package and test the `.rbz` release.