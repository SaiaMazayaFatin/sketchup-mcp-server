# Phase 4: Materials and Scenes

## Purpose

Add presentation and organization capabilities without weakening the safety
model established in earlier phases.

## Scope

Implement:

- Material inspection and application.
- Tag assignment.
- Scene inspection and creation.
- Active view inspection.
- Camera setting.

## MCP tools

- `list_materials`
- `apply_material`
- `set_entity_tag`
- `list_tags`
- `list_scenes`
- `get_active_view`
- `create_scene`
- `set_camera`

## Materials tasks

- Return material names, colors, and texture metadata when available.
- Resolve materials by stable name within the current model.
- Support applying a material to a group or selected face scope.
- Avoid creating duplicate materials unnecessarily.
- Report front/back face behavior explicitly.
- Validate that the requested material exists or is intentionally created.

## Tag tasks

- Read available tags.
- Validate tag names.
- Apply tags only to appropriate top-level containers by default.
- Warn against using tags to hide loose geometry incorrectly.
- Preserve the current visibility state unless explicitly changed.

## Scene and camera tasks

- Read scene names and indices.
- Return camera position, target, and up direction.
- Create a scene with explicit naming.
- Set camera properties with validated vectors.
- Preserve existing scene settings unless requested.
- Return a concise scene summary after changes.

## Ruby extension tasks

- Add material, tag, scene, and camera command modules.
- Keep each mutation in an undoable transaction.
- Handle name collisions explicitly.
- Validate vectors and camera values.
- Return useful errors for unsupported or unavailable features.

## Skill tasks

- Extend `sketchup-modeling` with material and organization guidance.
- Add a future `sketchup-rendering-scenes` Skill only after scene tools are
  stable.
- Document when a scene change is presentation-only versus model-changing.

## Testing

- Apply an existing material.
- Reject an unknown material.
- Assign a valid tag.
- Read scenes from a model with multiple scenes.
- Create a scene with a unique name.
- Handle a duplicate scene name.
- Read and set a camera.
- Verify undo behavior for each mutation.

## Acceptance criteria

1. Materials can be inspected and applied predictably.
2. Tag assignment follows documented SketchUp organization rules.
3. Scene creation handles duplicate names explicitly.
4. Camera values are validated and serialized consistently.
5. Unsupported features produce explicit errors.
6. Presentation changes remain undoable.

## Exit criteria

Agents can prepare a model for basic presentation and organization while
preserving existing materials, tags, scenes, and camera settings unless a
change is explicitly requested.

