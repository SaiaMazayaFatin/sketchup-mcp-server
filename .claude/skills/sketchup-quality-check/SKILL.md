---
name: sketchup-quality-check
description: "Audit and validate SketchUp model quality without changing it. Use for cleanup reports, loose geometry, empty groups, duplicate or overlapping entities, tag and material consistency, naming conventions, and pre-delivery checks."
argument-hint: "Describe the quality rules, scope, and report format to check."
---

# SketchUp Quality Check

## Use when

- The user wants a model audit, cleanup report, validation, or pre-delivery
  review.
- The request mentions loose geometry, empty groups, duplicate entities,
  overlapping geometry, naming, tags, materials, or organization standards.

## Procedure

1. Establish model connection, units, summary, and scope.
2. Inspect bounded entity pages and relevant nested containers.
3. Check one rule at a time: structure, naming, tags, materials, and geometry.
4. Record evidence with entity references and bounds where available.
5. Classify findings as error, warning, or informational.
6. Report false-positive limitations and incomplete coverage.
7. Do not mutate the model unless the user separately requests fixes.

## Invariants

- This Skill is read-only by default.
- Never call delete, transform, material, tag, or scene mutation tools during
  an audit.
- Do not call an issue a defect without evidence.
- Use bounded queries and disclose their limits.
- Keep proposed fixes separate from observed findings.
