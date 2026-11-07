# SketchUp MCP agent guidance

Use the repository's Agent Skills from `.agents/skills/` and choose the most
specific Skill based on the request:

- `sketchup-model-inspection` for read-only model questions, inventories,
  counts, bounds, selection, units, materials, tags, or scenes.
- `sketchup-modeling` for creating, editing, transforming, organizing, or
  deleting geometry and for materials, tags, scenes, or cameras.
- `sketchup-automation` for repeatable, batch, renaming, standardization, or
  deterministic multi-step workflows.
- `sketchup-quality-check` for audits, cleanup reports, validation, duplicate
  detection, and pre-delivery checks.

Load multiple Skills only when the request spans domains. Use
`sketchup-modeling` as the safety foundation for mutations.

Always inspect units and model scope first, use bounded queries, preview broad
or destructive changes, treat entity references as session-scoped, and never
execute arbitrary Ruby.
