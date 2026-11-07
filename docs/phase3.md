# Phase 3: Basic Geometry Operations

## Status

**Initial implementation in progress.** Grouped box, cylinder, and empty-group
creation, translation, and guarded deletion are implemented. Runtime validation
inside SketchUp remains pending.

Coordinates default to millimeters at the bridge boundary and can specify
`mm`, `cm`, `m`, `in`, or `ft` through the corresponding `*_unit` argument.

## Purpose

Enable safe creation and transformation of basic SketchUp geometry.

## Scope

Implement:

- Box creation.
- Cylinder creation.
- Group creation.
- Component instance placement where feasible.
- Entity transformations.
- Basic deletion with safety controls.

## MCP tools

- `create_box`
- `create_cylinder`
- `create_group`
- `create_component_instance`
- `transform_entities`
- `delete_entities`

## Operation design

Every write operation should include:

- Explicit operation name.
- Validated arguments.
- Optional human-readable label.
- Target entity references where applicable.
- Operation limits.
- Confirmation requirement where applicable.
- Structured result summary.

## Ruby extension tasks

- Implement geometry command handlers.
- Validate dimensions, coordinates, and transformation matrices.
- Create geometry inside a group by default.
- Use `model.start_operation` and `model.commit_operation`.
- Abort cleanly on failure.
- Return created entity references and bounds.
- Check that target references belong to the current model.
- Prevent cross-model or stale-session references.
- Avoid leaving partially created geometry after errors.

## Geometry rules

- Reject zero or negative dimensions.
- Reject non-finite numeric values.
- Enforce maximum dimensions and entity counts.
- Require explicit unit interpretation.
- Preserve existing model context.
- Prefer components for repeated instances.
- Avoid loose geometry unless explicitly requested.

## Transformation rules

- Validate target references.
- Support translation first.
- Add rotation and scaling only with clear coordinate semantics.
- Return before and after bounds.
- Reject transformations that exceed configured model limits.

## Delete behavior

- Default to preview or confirmation.
- Return the number and types of affected entities.
- Do not delete entities outside the requested scope.
- Use an undoable transaction.
- Report references that could not be deleted.

## Testing

### Unit tests

- Dimension validation.
- Transformation validation.
- Entity reference validation.
- Operation result serialization.

### Integration tests

- Create box and verify bounds.
- Create cylinder and verify entity structure.
- Transform a created group.
- Delete a created group.
- Undo each operation in SketchUp.
- Force an invalid operation and verify rollback.

## Acceptance criteria

1. Basic geometry is created in the expected coordinates.
2. Created geometry is grouped by default.
3. Invalid values never reach the SketchUp API.
4. Failed operations do not leave partial geometry.
5. Every mutation is undoable.
6. Results include created or modified entity references.
7. Delete operations cannot run accidentally without the required confirmation.

## Exit criteria

The system can perform small, predictable geometry operations while preserving
model integrity and a usable SketchUp undo history.
