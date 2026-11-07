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

## Documentation

- [Overall planning](docs/planning.md)
- [Phase 0: confirmed constraints and decisions](docs/phase0.md)
- [Phase 1: connectivity](docs/phase1.md)
- [Phase 2: read-only inspection](docs/phase2.md)
- [Phase 3: geometry operations](docs/phase3.md)
- [Phase 4: materials and scenes](docs/phase4.md)
- [Phase 5: preview and recovery](docs/phase5.md)
- [Phase 6: packaging and release](docs/phase6.md)
- [Installation and client setup](docs/installation.md)
- [Protocol message schema](protocol/messages.schema.json)
- [Protocol operation schema](protocol/operations.schema.json)

## Next step

Next, validate the extension inside SketchUp 2024 on Windows and macOS, then
package and test the `.rbz` release.