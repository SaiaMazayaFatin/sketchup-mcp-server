# Phase 13: Release Hardening and Broad Client Support

## Objective

Prepare the MCP for dependable use across Claude Code, Claude Desktop, Codex,
Copilot-compatible clients, Windows, and macOS.

## Protocol and compatibility

- Version the bridge protocol when payloads change incompatibly.
- Keep operation names stable after release.
- Return capability metadata so clients can discover supported features.
- Add structured error codes and remediation messages.
- Preserve backward compatibility for existing tools where practical.

## Security hardening

- Keep the bridge loopback-only.
- Keep token authentication mandatory.
- Use constant-time token comparison.
- Limit request size, response size, recursion depth, and operation counts.
- Do not log tokens, model contents, or sensitive paths.
- Audit every router operation for allowlist coverage.
- Reject unknown fields where schemas require strict input.

## Packaging

- Validate `.rbz` contents on Windows and macOS.
- Include version metadata and migration notes.
- Test install, upgrade, disable, and uninstall.
- Document token reset and bridge recovery.
- Ensure generated artifacts are excluded from source control.

## Skills and documentation

Update the canonical Skills and synchronized client locations with:

- Tool selection rules.
- Preview and confirmation rules.
- Entity-reference lifecycle.
- Unit and coordinate conventions.
- Recovery steps for stale references and failed operations.
- Examples for inspection, modeling, architecture, and automation.

## Release test matrix

Test at minimum:

- SketchUp 2024 on Windows.
- SketchUp 2024 on macOS.
- Claude Code.
- Claude Desktop.
- Codex-compatible MCP configuration.
- Clean install and upgrade from the prior package.
- Offline operation with no external service dependency.

## Acceptance criteria

- A clean user can install, connect, inspect, preview, execute, and undo.
- All documented tools appear in MCP discovery.
- Unsupported capabilities return clear errors.
- Security and size-limit tests pass.
- Packaging scripts produce installable artifacts on both platforms.
- Release documentation matches actual behavior.
