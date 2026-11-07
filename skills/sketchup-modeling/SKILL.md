---
name: sketchup-modeling
description: "Create and modify SketchUp geometry safely. Use for modeling, architectural massing, boxes, cylinders, groups, components, transforms, materials, tags, scenes, camera changes, and deleting or organizing entities."
argument-hint: "Describe the model change, dimensions, units, and target entities."
---

# SketchUp Modeling

## Use when

- The user wants to create, edit, move, transform, organize, or delete model
  entities.
- The request involves geometry, groups, components, materials, tags, scenes,
  or cameras.
- A read-only inspection is needed before a planned mutation.

## Procedure

1. Check `get_sketchup_status`.
2. Read `get_model_summary` and `get_model_units`.
3. Use `get_selection` when the request refers to selected objects.
4. Clarify missing dimensions, units, coordinate origin, or target scope.
5. Prefer existing groups, components, materials, and tags.
6. Use grouped geometry and explicit unit objects.
7. Preview deletion, destructive changes, and broad operations.
8. Execute the smallest safe operation.
9. Re-read the affected entities and verify bounds, names, tags, and materials.

## Tool selection

- Basic solids: `create_box`, `create_cylinder`.
- Containers: `create_group`.
- Translation: `transform_entities`.
- Existing materials/tags: `apply_material`, `set_entity_tag`.
- Views: `get_active_view`, `create_scene`, `set_camera`.
- Destructive changes: `preview_operation`, then `execute_operation`.
- Recovery: `undo_last_operation`.

## Invariants

- Never execute arbitrary Ruby.
- Never assume a numeric value's unit.
- Do not delete without explicit authorization and confirmation.
- Keep operations undoable and bounded.
- Treat entity references as valid only for the current bridge session.
- Report incomplete results and operation errors explicitly.
