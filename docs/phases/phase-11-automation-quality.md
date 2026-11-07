# Phase 11: Automation and Quality

## Objective

Let the AI perform repeatable multi-step work while keeping execution bounded,
observable, reversible, and safe.

## MCP operations

Add:

- `plan_operations`
- `preview_batch`
- `execute_batch`
- `cancel_operation`
- `measure_model`
- `validate_model`
- `find_duplicates`
- `find_empty_groups`
- `find_invalid_entities`
- `cleanup_model`
- `get_operation_progress`

## Batch plan format

A batch plan must contain:

- A generated plan ID.
- Ordered allowlisted operations.
- Explicit arguments for each operation.
- Preconditions where possible.
- Maximum operation count.
- Maximum affected entity count.
- Preview summary.
- Confirmation state.

No batch operation may contain Ruby source or arbitrary method names.

## Validation and quality reports

Reports should check:

- Invalid or erased entities.
- Empty groups.
- Duplicate names.
- Unused materials and tags.
- Hidden geometry.
- Unexpected tag assignments.
- Open boundaries where a closed solid is expected.
- Excessive entity counts.
- Model bounds and unit consistency.

Reports must distinguish errors, warnings, and informational findings.

## Progress and cancellation

- Long operations must return an operation ID.
- Progress must include completed, total or estimated total, and current step.
- Cancellation must stop at a safe transaction boundary.
- A cancelled operation must report whether rollback completed.
- The server must not claim success when completion is unknown.

## Acceptance criteria

- A multi-operation plan can be previewed as one unit.
- Batch execution is atomic where feasible or reports exact partial state.
- Limits prevent runaway recursive or high-count operations.
- Quality reports are deterministic on the fixture model.
- Cancellation and timeout behavior are tested.
