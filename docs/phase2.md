# Phase 2: Read-Only Inspection

## Status

**Initial implementation in progress.** The read-only MCP tools and bounded
SketchUp model reader are implemented. Runtime validation inside SketchUp is
still pending.

## Purpose

Provide reliable model understanding before any editing operation is enabled.

## Scope

Implement:

- Model metadata and summary.
- Units and coordinate information.
- Active selection inspection.
- Bounded entity listing.
- Materials, tags, and scenes listing.
- Initial `sketchup-modeling` and `sketchup-model-inspection` Skills.

All tools in this phase must be read-only.

## MCP tools

- `get_model_summary`
- `get_model_units`
- `get_selection`
- `get_entity_details`
- `list_entities`
- `list_materials`
- `list_tags`
- `list_scenes`

## Model summary fields

- Model name.
- Saved/unsaved state.
- File path when available.
- SketchUp version.
- Unit settings.
- Active entities context.
- Entity counts by type.
- Model bounds.
- Selection count.
- Tag and material counts.
- Scene count.

## Ruby extension tasks

- Implement bounded model traversal.
- Avoid unbounded recursive responses.
- Return stable references for the current bridge session.
- Serialize points, bounds, transformations, and colors consistently.
- Handle deleted or invalid entity references.
- Read active selection safely.
- Read materials, tags, and scenes.
- Report partial results explicitly if a bounded query reaches its limit.

## Skill tasks

### `sketchup-modeling`

- Require inspection before editing.
- Require unit confirmation.
- Define group/component preferences.
- Define verification behavior.

### `sketchup-model-inspection`

- Prefer read-only tools.
- Use bounded queries.
- Explain uncertainty when a result is incomplete.
- Never infer geometry details that were not returned.

## Performance requirements

- Every listing operation has pagination or a maximum count.
- Nested traversal has a depth limit.
- Large models return summaries before details.
- Responses have a maximum size.
- Entity queries should support filtering by type, parent, or selection.

## Testing

Test models:

- Empty model.
- Single box.
- Nested groups.
- Component instances.
- Materials and tags.
- Multiple scenes.
- Large model near configured limits.
- Unsaved model.
- Model with active selection.

## Acceptance criteria

1. Summary data is correct for known test models.
2. Selection data updates after selection changes.
3. Bounds use the documented coordinate convention.
4. Large queries are bounded and do not freeze SketchUp.
5. Deleted or invalid references return explicit errors.
6. Inspection tools do not mutate the model.
7. Both inspection Skills are usable with the available tools.

## Exit criteria

An agent can inspect a model, understand its units and structure, and plan a
change without requiring write access.
