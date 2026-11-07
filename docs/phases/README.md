# SketchUp MCP Future Implementation Phases

This directory contains the detailed implementation plan for expanding the
SketchUp MCP beyond the initial vertical slice.

The phases are intentionally ordered around risk:

1. Prove the existing bridge inside SketchUp.
2. Expand low-level model operations.
3. Add reusable component and hierarchy operations.
4. Build architectural workflows from tested primitives.
5. Add automation, validation, and performance controls.
6. Add documentation, import/export, and release hardening.

Every write operation must remain allowlisted, validated, undoable where
possible, and compatible with the preview-by-default execution policy.

## Phase documents

- [Phase 7 - Runtime harness and reliability](./phase-07-runtime-reliability.md)
- [Phase 8 - Advanced geometry](./phase-08-advanced-geometry.md)
- [Phase 9 - Components and hierarchy](./phase-09-components-hierarchy.md)
- [Phase 10 - Architectural modeling](./phase-10-architectural-modeling.md)
- [Phase 11 - Automation and quality](./phase-11-automation-quality.md)
- [Phase 12 - Scenes, documentation, and import/export](./phase-12-scenes-documentation-import-export.md)
- [Phase 13 - Release hardening and broad client support](./phase-13-release-hardening.md)

## Global rules

- Do not expose arbitrary Ruby execution.
- Do not allow an AI client to bypass the command router.
- Validate all input at the MCP schema and Ruby command boundaries.
- Keep entity references opaque, session-scoped, and invalidated when stale.
- Keep list and recursive operations bounded.
- Use SketchUp transactions for model mutations.
- Preview model-changing operations before execution by default.
- Require explicit confirmation for destructive or irreversible actions.
- Return structured results that include affected entities and verification data.
- Test each operation inside SketchUp; Ruby syntax checks alone are
  insufficient.

## Definition of done for every phase

- MCP tool definitions and Ruby router entries are implemented together.
- Protocol and operation schemas are updated when the payload changes.
- Skill guidance describes when and how to use the new tools.
- Positive, invalid-input, stale-reference, and rollback cases are tested.
- TypeScript checks, Ruby syntax checks, and targeted runtime checks pass.
- README or installation guidance is updated when user-facing behavior changes.
- No unrelated files or ignored local planning documents are committed.
