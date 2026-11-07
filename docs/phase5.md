# Phase 5: Preview, Confirmation, and Recovery

## Status

**Initial implementation in progress.** Session-bound previews, explicit
execution, delete confirmation, and last-operation undo are implemented.
Runtime validation inside SketchUp remains pending.

## Purpose

Make multi-step and destructive changes understandable, reviewable, and
recoverable before execution.

## Scope

Implement:

- Operation preview.
- Explicit execution of approved previews.
- Destructive-operation confirmation.
- Operation summaries.
- Undo support.
- Better diagnostics and recovery.

## Tool design

- `preview_operation`
- `execute_operation`
- `undo_last_operation`

The preview must describe the intended effect without mutating the model.
Execution must reference a preview ID and reject expired, altered, or
cross-session previews.

## Preview contents

- Preview ID.
- Protocol and operation version.
- Human-readable summary.
- Operation type.
- Target entity summaries.
- Expected created, changed, and deleted counts.
- Bounds before and after when available.
- Materials, tags, and scenes affected.
- Warnings.
- Required confirmation level.
- Expiration time.

## Confirmation policy

Require confirmation for:

- Deleting entities.
- Exploding groups or components.
- Purging unused content.
- Large batch changes.
- Changes exceeding configured geometry limits.
- Changes affecting many scenes, materials, or tags.

Read-only and small reversible changes may execute directly if configured.

## Ruby extension tasks

- Add transaction labels.
- Store operation metadata for the current session.
- Ensure failed execution rolls back.
- Return exact affected entity counts where possible.
- Reject stale preview IDs.
- Add safe undo behavior without interfering with normal SketchUp undo.

## MCP server tasks

- Store pending previews in memory with expiration.
- Never treat a preview as successful execution.
- Map confirmation state clearly to the client.
- Preserve error context.
- Avoid retrying non-idempotent operations automatically.

## Recovery behavior

- If SketchUp disconnects during execution, report unknown completion state.
- Do not automatically replay mutations unless the operation is proven
  idempotent.
- Provide a status check and model summary after reconnecting.
- Clearly distinguish rejected, failed, partially completed, and unknown-state
  operations.

## Testing

- Preview a box creation without changing entity counts.
- Execute a valid preview.
- Reject an expired preview.
- Reject a preview after arguments change.
- Require confirmation for deletion.
- Force an operation failure and verify rollback.
- Disconnect SketchUp during a request.
- Undo the last successful operation.

## Acceptance criteria

1. Preview does not mutate the model.
2. Execution requires a valid preview when policy requires it.
3. Destructive changes show an understandable summary.
4. Stale and reused previews are rejected.
5. Failed operations do not silently appear successful.
6. Unknown connection state is reported honestly.
7. Undo behavior is documented and testable.

## Exit criteria

The integration can support realistic workflows without allowing an agent to
make opaque, irreversible, or unexpectedly broad changes.
