# SketchUp MCP project guidance

## Skill routing

Choose the most specific workspace Skill based on the user's intent:

- Read-only model questions, inventories, counts, bounds, materials, tags, or
  scenes: load `sketchup-model-inspection`.
- Create, edit, transform, delete, or organize model geometry: load
  `sketchup-modeling`.
- Repeatable batch changes, renaming, standardization, or deterministic
  multi-step procedures: load `sketchup-automation`.
- Audits, validation reports, cleanup checks, duplicate detection, or model
  quality review: load `sketchup-quality-check`.

If a request spans multiple areas, load the smallest set of Skills needed and
use `sketchup-modeling` as the safety foundation for any mutation.

## Tool-use invariants

- Inspect the model and units before interpreting or changing geometry.
- Treat entity references as session-scoped.
- Use bounded inspection queries.
- Preview destructive or broad changes before execution.
- Never execute arbitrary Ruby.
- Verify model state after every mutation.
