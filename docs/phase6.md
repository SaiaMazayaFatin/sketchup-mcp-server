# Phase 6: Packaging, Compatibility, and Release

## Purpose

Turn the development implementation into an installable, documented, and
maintainable integration for Windows and macOS.

## Scope

- Package the SketchUp extension as `.rbz`.
- Support development-folder installation.
- Document MCP setup for Claude Code and Codex.
- Test SketchUp 2024 on Windows and macOS.
- Add versioning and compatibility checks.
- Add troubleshooting and connection recovery guidance.

## Extension packaging

- Use a stable top-level extension loader.
- Keep implementation files under the expected extension namespace.
- Exclude development files, test fixtures, and secrets from `.rbz`.
- Add extension version metadata.
- Verify installation and loading from a clean SketchUp profile.
- Document uninstall and upgrade behavior.

## MCP server packaging

- Define supported Node.js versions.
- Provide a reproducible install command.
- Provide a production start command.
- Ensure logs go to stderr.
- Validate configuration at startup.
- Report missing bridge credentials clearly.
- Document client-specific MCP registration.

## Compatibility matrix

Track at minimum:

| Environment | Extension | MCP server | Status |
|---|---|---|---|
| Windows + SketchUp 2024 | Development folder | Local Node.js | To test |
| Windows + SketchUp 2024 | `.rbz` | Local Node.js | To test |
| macOS + SketchUp 2024 | Development folder | Local Node.js | To test |
| macOS + SketchUp 2024 | `.rbz` | Local Node.js | To test |

## Documentation

Create or update:

- Installation guide.
- Claude Code MCP configuration.
- Codex MCP configuration.
- Extension troubleshooting.
- Bridge authentication guidance.
- Supported tools and Skills.
- Known limitations.
- Security model.
- Upgrade and rollback instructions.

## Release checks

- Run TypeScript type checking.
- Run MCP server unit tests.
- Run Ruby syntax checks and extension tests where available.
- Validate all protocol schemas.
- Test clean installation.
- Test invalid configuration.
- Test bridge restart and SketchUp restart.
- Check that no secrets are packaged.
- Check that logs do not expose sensitive model data unnecessarily.

## Acceptance criteria

1. A new user can install the extension from `.rbz`.
2. A developer can load the extension from a development folder.
3. Claude Code setup is documented and works.
4. Codex setup is documented and works.
5. Windows and macOS compatibility results are recorded.
6. Version mismatches fail with actionable messages.
7. The package contains no secrets or development-only files.
8. A clean user can recover from a disconnected bridge.

## Exit criteria

The project has a repeatable installation, documented compatibility, and a
release process suitable for continued development and user testing.

