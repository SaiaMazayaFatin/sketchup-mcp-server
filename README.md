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