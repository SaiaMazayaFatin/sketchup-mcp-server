---
name: sketchup-automation
description: "Run repeatable and deterministic SketchUp workflows. Use for batch operations, renaming groups or components, standardizing tags and materials, generating repeated geometry, exporting model information, and multi-step automation."
argument-hint: "Describe the repeatable operation, selection criteria, limits, and expected result."
---

# SketchUp Automation

## Use when

- The user requests a batch or repeatable model operation.
- Entities must be renamed, tagged, materialized, or standardized by criteria.
- A multi-step deterministic workflow is needed.
- The user wants structured model data exported or checked.

## Procedure

1. Inspect model summary, units, selection, and relevant entity pages.
2. Define exact matching criteria and an explicit affected-entity limit.
3. Preview the complete operation and report expected counts.
4. Confirm naming, tag, material, and component collision behavior.
5. Execute in small, undoable batches.
6. Re-inspect affected entities and report successes and failures separately.
7. Stop on ambiguous scope or unexpected counts.

## Invariants

- Never use arbitrary Ruby or unbounded traversal.
- Do not silently skip failed entities.
- Do not create duplicate materials or components without authorization.
- Keep batch limits explicit.
- Require confirmation for deletion, purge, explode, or broad changes.
- Preserve existing organization unless the request changes it.
