# Phase 0: Confirm Constraints and Design Decisions

## Status

**Complete.** The decisions in this document were reviewed and confirmed.
Phase 1 may now begin.

## 1. Decisions

| Area | Proposed decision | Status |
|---|---|---|
| MCP client transport | MCP server uses stdio | Confirmed |
| SketchUp bridge transport | Line-delimited JSON over loopback TCP | Confirmed |
| Bridge bind address | `127.0.0.1` only | Confirmed |
| Bridge startup | Start when the extension loads; expose status in SketchUp | Confirmed |
| SketchUp instances | One active SketchUp instance per MCP server | Confirmed |
| Target SketchUp | SketchUp 2024 | Confirmed |
| Target platforms | Windows and macOS | Confirmed |
| Node.js | Node.js 20 LTS or newer compatible LTS | Confirmed |
| Ruby execution | No arbitrary Ruby evaluation | Confirmed |
| Authentication | Per-user random token, stored outside the repository | Confirmed |
| Message format | UTF-8 JSON, one complete JSON object per line | Confirmed |
| Protocol version | `1` for the first implementation | Confirmed |
| Entity references | Session-scoped opaque references, never persistent IDs | Confirmed |
| Dimensions | `{ "value": number, "unit": "mm" }` internally | Confirmed |
| Default length unit | Millimeters at the bridge boundary | Confirmed |
| Destructive changes | Preview plus explicit execution | Confirmed |
| Small reversible changes | Direct execution may be allowed by tool policy | Confirmed |
| Request timeout | 10 seconds by default, configurable per operation | Confirmed |
| Maximum message size | 1 MiB request and 4 MiB response | Confirmed |

### Why loopback TCP instead of WebSocket?

Loopback TCP avoids adding a WebSocket dependency to the SketchUp extension and
is sufficient for a single local MCP server. Newline-delimited JSON makes
framing explicit and can be implemented with Ruby's standard library. The
protocol can be replaced or adapted later without changing MCP tool schemas.

### Why session-scoped entity references?

SketchUp entity IDs are not a safe cross-session identity mechanism. The
extension should map an opaque reference to an entity for the current model and
bridge session. References become invalid after model or connection changes and
must produce an explicit `STALE_REFERENCE` error.

### Why millimeters at the bridge boundary?

SketchUp supports multiple model unit settings. The bridge should not make
agents infer units from the UI. Requests use explicit units and the extension
converts them to SketchUp's internal units. The read-only status response still
reports the model's configured units.

## 2. Scope for Phase 0

- Define the bridge envelope.
- Define authentication and lifecycle behavior.
- Define units and coordinates.
- Define error codes.
- Define limits.
- Define logging rules.
- Define compatibility checks.
- Keep all implementation files safe to begin in Phase 1.

## 3. Bridge lifecycle

1. The extension loads and starts a loopback listener.
2. The extension creates or loads a per-user token.
3. The MCP server connects and authenticates before sending operations.
4. The server sends a `hello` request with protocol version and client details.
5. The extension returns capabilities and SketchUp status.
6. Requests are processed sequentially for one active model.
7. The extension closes the listener when it unloads or SketchUp exits.
8. The MCP server reports disconnected state rather than retrying mutations.

The MCP server may reconnect for read-only status checks. Non-idempotent
operations must never be replayed automatically after an uncertain disconnect.

## 4. Message envelope

Every request uses this shape:

```json
{
  "protocol_version": 1,
  "request_id": "req_01J...",
  "operation": "get_sketchup_status",
  "auth_token": "local-secret",
  "arguments": {}
}
```

Every response uses this shape:

```json
{
  "protocol_version": 1,
  "request_id": "req_01J...",
  "success": true,
  "result": {}
}
```

Errors use:

```json
{
  "protocol_version": 1,
  "request_id": "req_01J...",
  "success": false,
  "error": {
    "code": "INVALID_ARGUMENT",
    "message": "Width must be greater than zero",
    "details": {}
  }
}
```

## 5. Error codes

The initial error vocabulary is:

- `INVALID_ENVELOPE`: message shape or framing is invalid.
- `UNSUPPORTED_PROTOCOL`: protocol version is not supported.
- `UNAUTHENTICATED`: token is missing or invalid.
- `UNAUTHORIZED_OPERATION`: operation is not allowed.
- `INVALID_ARGUMENT`: operation arguments fail validation.
- `NOT_CONNECTED`: SketchUp is unavailable.
- `MODEL_NOT_READY`: model cannot currently accept the operation.
- `STALE_REFERENCE`: entity reference is no longer valid.
- `LIMIT_EXCEEDED`: request exceeds configured safety limits.
- `CONFLICT`: requested name, entity, or state conflicts with the model.
- `OPERATION_FAILED`: SketchUp rejected or failed the operation.
- `OPERATION_TIMEOUT`: operation exceeded its deadline.
- `UNKNOWN_COMPLETION`: connection ended before mutation completion was known.
- `INTERNAL_ERROR`: unexpected implementation error with diagnostic logging.

Errors returned to an MCP client must be actionable and must not expose the
authentication token or unnecessary model-sensitive data.

## 6. Units and coordinates

### Length values

Lengths use an explicit object:

```json
{
  "value": 1000,
  "unit": "mm"
}
```

Supported initial units:

- `mm`
- `cm`
- `m`
- `in`
- `ft`

The extension converts values to SketchUp's internal representation. The
protocol uses a right-handed coordinate system with `[x, y, z]`, and the
extension documents the model axes in the status response.

### Validation

- Values must be finite numbers.
- Zero and negative dimensions are rejected where inappropriate.
- Unit names are case-sensitive protocol values.
- Every operation documents whether coordinates are absolute or relative.

## 7. Authentication and secrets

- Generate a cryptographically random token on first setup.
- Store it in the user-specific application data directory.
- Never store it in source control, logs, Skills, or MCP responses.
- Compare tokens without logging either input.
- Reject unauthenticated requests before operation dispatch.
- Keep the listener on loopback.
- Provide a documented token reset procedure for local recovery.

The exact platform-specific storage paths should be implemented in Phase 1
using SketchUp and Node conventions rather than hard-coded repository paths.

## 8. Limits

Initial conservative limits:

| Limit | Value |
|---|---:|
| Request size | 1 MiB |
| Response size | 4 MiB |
| Entity details per request | 500 |
| Traversal depth | 8 |
| Entities created by one operation | 10,000 |
| Default operation timeout | 10 seconds |
| Preview expiration | 5 minutes |

Limits must return `LIMIT_EXCEEDED`; they must not silently truncate mutation
requests. Read-only list operations may return an explicit pagination marker.

## 9. Logging

Log to stderr in the MCP server and to a controlled SketchUp log in the
extension. Include:

- Timestamp.
- Request ID.
- Operation name.
- Duration.
- Success or error code.
- Protocol version.

Do not log:

- Authentication tokens.
- Full model paths unless explicitly enabled for diagnostics.
- Entire model contents by default.
- Unbounded request or response bodies.

## 10. Compatibility checks

Phase 1 must verify:

- SketchUp major/minor version is compatible with the extension.
- Protocol version is supported.
- MCP server Node.js version is supported.
- The bridge token is available.
- The selected port is available or can be configured.

Unsupported combinations must fail with a clear startup message.

## 11. Phase 0 deliverables

- This decision record.
- [messages.schema.json](../protocol/messages.schema.json)
- [operations.schema.json](../protocol/operations.schema.json)
- Error vocabulary and limits.
- Phase 1 implementation backlog.

## 12. Exit criteria

Phase 0 is complete because the decisions have been confirmed and:

1. The bridge transport and framing are fixed.
2. Authentication and token storage behavior are fixed.
3. Unit and coordinate conventions are fixed.
4. Protocol version and error codes are fixed.
5. Limits and timeout defaults are fixed.
6. Phase 1 can be implemented without architectural decisions remaining.
