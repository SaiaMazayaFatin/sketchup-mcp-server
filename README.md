# SketchUp MCP

Local MCP integration for connecting Claude Code and Codex to SketchUp 2024 on
Windows and macOS.

## Project status

Phase 0 is complete. The agreed architecture is:

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

## Documentation

- [Overall planning](docs/planning.md)
- [Phase 0: confirmed constraints and decisions](docs/phase0.md)
- [Phase 1: connectivity](docs/phase1.md)
- [Protocol message schema](protocol/messages.schema.json)
- [Protocol operation schema](protocol/operations.schema.json)

## Next step

Begin Phase 1 by implementing the authenticated bridge, MCP stdio server, and
the `ping_sketchup` and `get_sketchup_status` tools.