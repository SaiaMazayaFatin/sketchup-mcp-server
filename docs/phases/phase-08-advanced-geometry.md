# Phase 8: Advanced Geometry

## Objective

Give the AI composable low-level geometry tools so it can construct and edit
models beyond boxes and cylinders without exposing arbitrary Ruby.

## MCP operations

Add tools for:

- `create_face`
- `create_edges`
- `create_circle`
- `create_arc`
- `create_polygon`
- `pushpull_face`
- `offset_face`
- `move_entities`
- `rotate_entities`
- `scale_entities`
- `copy_entities`
- `intersect_entities`
- `erase_entities`
- `measure_distance`
- `measure_angle`

Use explicit units for lengths and explicit degrees for angles.

## Ruby modules

Create focused modules rather than growing `geometry_commands.rb` without
structure:

- `primitive_commands.rb`
- `face_commands.rb`
- `transform_commands.rb`
- `intersection_commands.rb`
- `measurement_commands.rb`

All modules should share entity resolution, validation, transaction, and
summary helpers.

## Input design

- Coordinates are three-number arrays with an explicit unit.
- Point lists have a maximum count.
- Faces must contain at least three non-collinear points.
- Segments have a safe minimum and maximum.
- Angles must be finite and bounded.
- Scale factors must be finite and positive.
- Entity lists must be non-empty and deduplicated.

## Geometry rules

- Reject self-intersecting polygons unless explicitly supported.
- Reject zero-area faces.
- Reject transformations on erased or invalid entities.
- Preserve group/component boundaries by default.
- Make in-place mutation explicit; default to copying when ambiguity exists.
- Return created and affected entity references.

## Preview and transactions

Every geometry mutation must:

1. Validate without changing the model.
2. Produce a bounded preview summary.
3. Execute inside one SketchUp transaction.
4. Roll back on any exception.
5. Return before/after bounds and references.

## Acceptance criteria

- Faces, circles, arcs, push/pull, offset, rotate, scale, and copy work in
  SketchUp 2024.
- Units and angle conversions are verified with known measurements.
- Invalid geometry is rejected before mutation.
- Composite operations are atomic.
- Undo restores the previous model state.
- Runtime tests cover groups, components, nested contexts, and world axes.
