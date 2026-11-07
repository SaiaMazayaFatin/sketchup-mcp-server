# Phase 10: Architectural Modeling

## Objective

Provide high-level architectural operations built on tested geometry and
hierarchy primitives.

## Initial operations

Implement:

- `create_wall`
- `create_floor`
- `create_slab`
- `create_roof`
- `create_door`
- `create_window`
- `create_stair`
- `create_room`

Each operation should create a named group or component and return its
entity reference, bounds, materials, and generated sub-elements.

## Shared design

Define reusable value objects for:

- 2D and 3D points.
- Lengths and angles.
- Wall paths and thickness.
- Floor boundaries.
- Opening placement.
- Roof pitch and overhang.
- Stair rise, run, width, and count.

Do not duplicate unit conversion or polygon validation in each command.

## Wall and opening model

Walls should support:

- Straight segments first.
- Start and end points.
- Height and thickness.
- Optional material and tag.
- Named openings.

Doors and windows should be represented as controlled opening operations or
component placements, not destructive face searches with ambiguous results.

## Roof and stair constraints

- Reject impossible slopes and zero dimensions.
- Validate stair rise/run against configured ranges.
- Require a closed floor boundary for rooms and slabs.
- Return warnings for unsupported or approximate geometry.

## AI workflow

The Skill should instruct the AI to:

1. Inspect units and existing hierarchy.
2. Search for target rooms, levels, or reference geometry.
3. Preview the architectural operation.
4. Explain affected geometry and assumptions.
5. Request confirmation.
6. Execute and verify bounds, counts, and names.

## Acceptance criteria

- A simple wall, floor, roof, door, window, stair, and room can be created
  from explicit parameters.
- Operations create predictable hierarchy and names.
- Invalid dimensions and open boundaries are rejected.
- Preview output is understandable to a user.
- Operations are atomic and undoable.
- Runtime tests verify metric and imperial units.
