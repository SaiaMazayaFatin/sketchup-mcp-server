---
name: sketchup-model-inspection
description: "Inspect and understand existing SketchUp models without changing them. Use for model summaries, entity counts, bounds, selection, units, materials, tags, scenes, inventories, and answering questions about model contents."
argument-hint: "Describe what model information or entity inventory you need."
---

# SketchUp Model Inspection

## Use when

- The user asks what is in a model.
- The user wants counts, bounds, units, selected entities, materials, tags,
  scenes, names, or entity details.
- The user asks for analysis before deciding whether to edit the model.

## Procedure

1. Call `ping_sketchup` or `get_sketchup_status`.
2. Call `get_model_summary` and `get_model_units`.
3. Inspect `get_selection` when selection is relevant.
4. Use `list_entities` with a limit and type filter.
5. Use `get_entity_details` only for relevant references.
6. Read materials, tags, and scenes separately.
7. State limits, stale references, unavailable data, and uncertainty.

## Invariants

- Inspection is read-only: do not call mutation tools.
- Do not infer geometry that tools did not return.
- Never describe a bounded page as a complete inventory.
- Refresh session-scoped references after reconnecting.
- Prefer summaries before large listings.
