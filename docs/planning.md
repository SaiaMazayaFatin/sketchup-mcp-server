# SketchUp MCP and Skills Integration Plan

## 1. Goal

Build a local integration that allows Claude Code and Codex to inspect and modify
SketchUp models through MCP tools and a SketchUp Ruby extension.

The initial target is SketchUp 2024 on Windows and macOS, with both development
folder installation and `.rbz` packaging.

## 2. Recommended architecture

```text
Claude Code / Codex
        |
        | MCP over stdio
        v
TypeScript MCP Server
        |
        | Local authenticated TCP or WebSocket bridge
        v
SketchUp Ruby Extension
        |
        v
SketchUp Ruby API
```

### Responsibilities

#### MCP server

- Expose tools using the MCP protocol.
- Validate tool arguments with schemas.
- Manage communication with SketchUp.
- Convert bridge responses into MCP results.
- Report errors explicitly.
- Manage request IDs, timeouts, and connection state.
- Support Claude Code and Codex through standard MCP configuration.

#### SketchUp extension

- Run inside SketchUp.
- Listen only on the local machine by default.
- Authenticate bridge requests.
- Validate and route allowlisted operations.
- Execute changes through the SketchUp Ruby API.
- Wrap changes in SketchUp undoable transactions.
- Return structured model and operation results.

#### Skills

- Explain how the AI should reason about SketchUp tasks.
- Define safe workflows and verification requirements.
- Guide tool selection.
- Keep domain-specific behavior separate from the MCP implementation.

The system must not execute arbitrary Ruby code received from an AI client.

## 3. Technology choices

| Area | Choice |
|---|---|
| SketchUp integration | Ruby extension using the SketchUp Ruby API |
| MCP server | TypeScript with Node.js |
| Client transport | MCP over stdio |
| Local bridge | TCP or WebSocket on `127.0.0.1` |
| Validation | Shared JSON Schema or TypeScript schema definitions |
| Target SketchUp | SketchUp 2024 |
| Platforms | Windows and macOS |
| Extension packaging | Development folder and `.rbz` |

TypeScript is recommended for the MCP server because of its MCP ecosystem,
type safety, schema support, and CLI packaging. Ruby is required for direct
SketchUp API access.

## 4. Skill architecture

Skills describe behavior and workflow. MCP tools provide executable
capabilities. They should remain separate.

### 4.1 `sketchup-modeling`

The shared foundation Skill.

- Inspect the model before editing.
- Confirm units and coordinate assumptions.
- Prefer groups and components over loose geometry.
- Preserve existing model organization.
- Use undoable operations.
- Preview risky changes.
- Verify the result after each change.
- Never delete existing content without clear authorization.

### 4.2 `sketchup-model-inspection`

Read-only model analysis.

- Read model metadata and units.
- Inspect active selection.
- Count and classify entities.
- Inspect groups, components, materials, tags, and scenes.
- Report model bounds.
- Identify possible cleanup issues.
- Do not modify the model unless explicitly requested.

### 4.3 `sketchup-automation`

Repeatable and deterministic workflows.

- Rename groups and components.
- Apply materials or tags to matching entities.
- Generate repeated geometry.
- Standardize model organization.
- Export structured model information.
- Validate each batch operation and report partial failures.

### 4.4 `sketchup-quality-check`

Model validation and reporting.

- Detect loose geometry.
- Find empty groups and components.
- Check tag and material consistency.
- Check naming conventions.
- Detect suspicious duplicate or overlapping geometry where practical.
- Produce a report without automatically changing the model.

### Future specialized Skills

These should be added after the foundation is stable:

- `sketchup-architecture`
- `sketchup-interior-design`
- `sketchup-site-landscape`
- `sketchup-rendering-scenes`
- `sketchup-component-library`

Specialized Skills should depend conceptually on `sketchup-modeling`, but the
MCP server should remain domain-neutral.

## 5. MCP tool design

Tool names and schemas should be stable, explicit, and safe. The first
capability groups are:

### Connection and status

- `get_sketchup_status`
- `ping_sketchup`

### Inspection

- `get_model_summary`
- `get_model_units`
- `get_selection`
- `get_entity_details`
- `list_entities`
- `list_materials`
- `list_tags`
- `list_scenes`

### Geometry

- `create_box`
- `create_cylinder`
- `create_group`
- `create_component_instance`
- `transform_entities`
- `delete_entities`

### Materials and organization

- `apply_material`
- `set_entity_tag`

### Scenes and views

- `get_active_view`
- `create_scene`
- `set_camera`

### Safety and operations

- `preview_operation`
- `execute_operation`
- `undo_last_operation`

The initial implementation does not need to expose every tool at once. The
protocol should be designed so these capabilities can be added without
breaking existing clients.

## 6. Bridge protocol

The MCP server and extension should exchange structured messages rather than
Ruby source code.

### Request

```json
{
  "request_id": "req-123",
  "operation": "create_box",
  "arguments": {
    "origin": [0, 0, 0],
    "width": 1000,
    "depth": 500,
    "height": 250
  }
}
```

### Success response

```json
{
  "request_id": "req-123",
  "success": true,
  "result": {
    "created_entities": [
      {
        "type": "group",
        "id": 42
      }
    ]
  }
}
```

### Error response

```json
{
  "request_id": "req-123",
  "success": false,
  "error": {
    "code": "INVALID_ARGUMENT",
    "message": "Width must be greater than zero"
  }
}
```

The protocol should define:

- Message framing.
- Request IDs and correlation.
- Authentication.
- Error codes.
- Timeout behavior.
- Maximum request and response sizes.
- Operation result formats.
- Extension and protocol version negotiation.

## 7. Safety requirements

### Required from the first implementation

- Bind the bridge to `127.0.0.1` by default.
- Use a generated authentication token.
- Use an allowlist of supported operations.
- Reject unknown operations.
- Validate all arguments on both sides.
- Do not evaluate arbitrary Ruby.
- Use SketchUp transactions for model changes.
- Return explicit errors; do not silently ignore failures.
- Apply reasonable limits to entity counts and geometry complexity.
- Keep read-only operations separate from destructive operations.

### Destructive operations

Deletion, exploding, purging, and large batch changes should require either:

1. A preview followed by explicit execution, or
2. A dedicated confirmation flag and clear operation summary.

The normal SketchUp undo stack must remain usable.

## 8. Proposed repository structure

```text
sketchup-mcp/
├── mcp-server/
│   ├── src/
│   │   ├── index.ts
│   │   ├── bridge/
│   │   ├── tools/
│   │   ├── schemas/
│   │   └── protocol/
│   ├── package.json
│   └── tsconfig.json
├── sketchup-extension/
│   ├── sketchup_mcp.rb
│   └── sketchup_mcp/
│       ├── bridge_server.rb
│       ├── command_router.rb
│       ├── model_reader.rb
│       ├── geometry_commands.rb
│       ├── material_commands.rb
│       ├── scene_commands.rb
│       └── transaction_manager.rb
├── skills/
│   ├── sketchup-modeling/
│   │   └── SKILL.md
│   ├── sketchup-model-inspection/
│   │   └── SKILL.md
│   ├── sketchup-automation/
│   │   └── SKILL.md
│   └── sketchup-quality-check/
│       └── SKILL.md
├── protocol/
│   ├── messages.schema.json
│   └── operations.schema.json
└── README.md
```

## 9. Implementation phases

### Phase 0: Confirm constraints

- Confirm SketchUp 2024 API behavior on Windows and macOS.
- Confirm the preferred local bridge transport.
- Confirm the minimum Node.js version.
- Confirm Claude Code and Codex MCP configuration formats.
- Define units, coordinate conventions, and error conventions.

### Phase 1: Connectivity

- Create the minimal Ruby extension.
- Start a local authenticated bridge.
- Create the TypeScript MCP server.
- Add `ping_sketchup` and `get_sketchup_status`.
- Return SketchUp version, platform, model name, and connection state.

### Phase 2: Read-only inspection

- Implement model summary.
- Implement selection inspection.
- Add entity, material, tag, and scene listing.
- Add `sketchup-modeling` and `sketchup-model-inspection`.
- Test against empty, simple, and nested models.

### Phase 3: Basic geometry

- Add box, cylinder, group, and transform operations.
- Use transactions and return created entity metadata.
- Add argument validation and operation limits.
- Add verification after each operation.

### Phase 4: Materials and scenes

- Read and apply materials.
- Read and create scenes.
- Read and set camera properties.
- Add scene-specific tool schemas.

### Phase 5: Preview and safety

- Implement operation previews.
- Implement explicit execution for risky operations.
- Add undo support and operation summaries.
- Add structured error codes and diagnostics.

### Phase 6: Packaging and compatibility

- Package the extension as `.rbz`.
- Test development-folder installation.
- Test Windows and macOS.
- Document MCP setup for Claude Code and Codex.
- Add troubleshooting and connection recovery behavior.

## 10. First milestone acceptance criteria

The first milestone is complete when:

1. SketchUp 2024 is running with the extension loaded.
2. Claude Code or Codex can connect through the MCP server.
3. `get_sketchup_status` returns a valid status.
4. `get_model_summary` returns model name, units, entity counts, and bounds.
5. `get_selection` returns the current selection.
6. `create_box` creates a grouped box in SketchUp.
7. The operation appears in the SketchUp undo stack.
8. Invalid dimensions produce an explicit error.
9. The bridge rejects unauthenticated requests.
10. The same basic workflow works on Windows and macOS.

## 11. Testing strategy

### Unit tests

- Tool argument schemas.
- Protocol message encoding and decoding.
- Request correlation and timeout handling.
- Ruby command validation.
- Geometry calculations.
- Error mapping.

### Integration tests

- MCP server to bridge communication.
- Bridge authentication.
- Status and inspection responses.
- Geometry creation and transformation.
- Transaction and undo behavior.

### Manual SketchUp tests

- Empty model.
- Existing model with nested groups.
- Active selection.
- Different unit settings.
- Materials and scenes.
- Invalid and oversized operations.
- Windows and macOS installation.

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| SketchUp UI thread restrictions | Route model operations through the extension's safe execution path |
| Model corruption from malformed commands | Validate schemas and use transactions |
| SketchUp becoming unresponsive | Add operation limits and avoid unbounded batch operations |
| Client-specific MCP differences | Use standard MCP tools and document client setup separately |
| Protocol changes breaking clients | Version the bridge protocol |
| Security exposure on local network | Bind to loopback and require authentication |
| Ambiguous dimensions | Require explicit units or use model units transparently |
| Large or complex models | Return summaries first and support bounded queries |

## 13. Decisions still needed

Before implementation begins, confirm:

1. TCP or WebSocket for the local bridge.
2. Whether the bridge should start automatically when SketchUp opens.
3. Whether a user-facing SketchUp toolbar/menu is required in the first version.
4. Whether geometry dimensions should be sent as numeric model units or unit strings
   such as `"1000 mm"`.
5. Whether preview should be required for all destructive operations or only
   large/risky operations.
6. The first supported authentication and connection recovery behavior.
7. Whether the initial project should support one SketchUp instance or multiple
   concurrent instances.

## 14. Recommended next step

Resolve the decisions in Section 13, then implement Phase 1 only:

```text
ping_sketchup
get_sketchup_status
get_model_summary
```

Do not begin with arbitrary code execution or broad geometry APIs. Establishing
a narrow, authenticated, observable connection first will make the later Skills
and tools safer and easier to test.
