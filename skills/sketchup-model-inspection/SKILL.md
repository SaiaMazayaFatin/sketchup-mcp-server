# SketchUp Model Inspection

Use this Skill for read-only analysis of a SketchUp model.

## Workflow

1. Check the SketchUp connection.
2. Read the model summary and units.
3. Inspect the active selection if relevant.
4. Use bounded entity queries with an explicit limit.
5. Request details only for relevant entity references.
6. Inspect materials, tags, and scenes as separate resources.
7. Report what was observed and identify any bounded or unavailable data.

## Rules

- Do not mutate the model.
- Do not infer geometry that was not returned by an inspection tool.
- Treat entity references as valid only for the current bridge session.
- Prefer summaries and filtered pages for large models.
- Never describe a partial listing as a complete model inventory.
- If an entity reference becomes stale, refresh the model summary or listing.

## Useful tools

- `get_sketchup_status`
- `get_model_summary`
- `get_model_units`
- `get_selection`
- `get_entity_details`
- `list_entities`
- `list_materials`
- `list_tags`
- `list_scenes`