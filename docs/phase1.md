# Phase 1: Connectivity

## Purpose

Create the smallest complete path from Claude Code or Codex to a running
SketchUp instance.

## Scope

Implement:

- A TypeScript MCP server.
- A SketchUp Ruby extension.
- A local authenticated bridge.
- `ping_sketchup`.
- `get_sketchup_status`.

Do not implement arbitrary Ruby execution or geometry editing in this phase.

## MCP server tasks

- Initialize the Node.js and TypeScript project.
- Add the MCP server entry point.
- Implement stdio transport.
- Add a typed bridge client.
- Generate request IDs.
- Add connection timeout handling.
- Map bridge errors to MCP tool errors.
- Add structured logging to stderr, never stdout.
- Register `ping_sketchup` and `get_sketchup_status`.
- Add client configuration examples for Claude Code and Codex.

## SketchUp extension tasks

- Create the extension loader file.
- Add a namespaced Ruby module.
- Create the extension menu or toolbar status entry if selected in Phase 0.
- Start the local bridge server.
- Generate or load the authentication token.
- Validate the protocol version.
- Implement the command router.
- Implement `ping` and `get_status`.
- Return SketchUp version, platform, model name, model path when available,
  active selection count, and connection status.

## Protocol requirements

- Every request has a request ID.
- Every response contains the same request ID.
- Every message has a protocol version.
- Authentication happens before operation dispatch.
- Unknown operations return a typed error.
- Malformed JSON or invalid envelopes return explicit errors.
- Requests have a finite timeout.

## Testing

### Unit tests

- Request ID generation.
- Message validation.
- Authentication checks.
- Error mapping.
- Status response schema.

### Manual tests

- Start SketchUp with the extension loaded.
- Start the MCP server from each client.
- Call `ping_sketchup`.
- Call `get_sketchup_status`.
- Close SketchUp and verify a useful connection error.
- Use an invalid token and verify rejection.
- Send an unsupported operation and verify rejection.

## Deliverables

- Working MCP server package.
- Working development-folder extension.
- Initial bridge protocol implementation.
- Client setup documentation.
- Logs that make connection failures diagnosable.

## Acceptance criteria

1. The MCP server starts through stdio.
2. SketchUp 2024 loads the extension without errors.
3. The bridge listens only on loopback.
4. Authenticated ping succeeds.
5. Status includes SketchUp version and model name.
6. Invalid authentication fails explicitly.
7. SketchUp shutdown does not hang the MCP server.
8. Windows and macOS behavior is documented.

## Exit criteria

The complete client-to-SketchUp path is stable enough to support read-only
inspection work in Phase 2.

