# SketchUp Modeling

## Core workflow

1. Inspect the active model before making changes.
2. Confirm the model units and coordinate assumptions.
3. Prefer groups and components over loose geometry.
4. Preserve existing names, tags, materials, and organization unless a change
   is explicitly requested.
5. Use small, undoable operations.
6. Preview destructive or broad changes before execution.
7. Verify the resulting model after every mutation.

## Inspection rules

- Start with `get_sketchup_status` or `get_model_summary`.
- Use `get_model_units` before interpreting dimensions.
- Use `get_selection` when the request refers to selected objects.
- Use bounded listing tools instead of requesting the entire model.
- Treat entity references as session-scoped and refresh them after reconnecting.

## Safety rules

- Never request or execute arbitrary Ruby code.
- Do not delete, explode, or purge model content without explicit authorization.
- Do not assume a numeric dimension's unit.
- Report incomplete or bounded results honestly.