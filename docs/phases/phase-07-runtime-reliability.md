# Phase 7: Runtime Harness and Reliability

## Objective

Prove that the current MCP and Ruby extension work reliably inside SketchUp
2024 on Windows and macOS before adding a larger command surface.

## Scope

- Install and load the extension in SketchUp 2024.
- Verify bridge startup, authentication, UI-thread dispatch, and shutdown.
- Exercise every existing read and write operation against a disposable model.
- Add a repeatable SketchUp-side test fixture and an external smoke-test script.
- Improve timeout, error, stale-reference, and rollback reporting.

## Implementation plan

### 1. Test fixture

Create a deterministic fixture model containing:

- Groups with names and nested geometry.
- Component definitions and instances.
- Materials with known colors.
- Tags with known visibility.
- At least two scenes.
- A known selection and camera.

The fixture must be recreatable without relying on a user file path.

### 2. Runtime test harness

Add a test-only command or fixture loader that is not exposed as arbitrary Ruby.
It should be explicitly named, allowlisted, and disabled unless a test mode is
enabled. The harness must be able to:

- Reset the active test model.
- Create known fixture entities.
- Return stable assertions through the bridge.
- Clean up after a test run.

### 3. External smoke tests

Add a Node-based test runner that connects to the bridge and verifies:

1. `ping_sketchup`.
2. Status and model summary.
3. Top-level and nested entity listing.
4. Search and entity details.
5. Box, cylinder, and group creation.
6. Translation, materials, tags, scenes, and camera.
7. Preview non-mutation.
8. Explicit execution.
9. Delete confirmation rejection.
10. Undo and stale-reference behavior.

### 4. Reliability fixes

- Add a request timeout on the Ruby UI dispatch queue.
- Return a specific timeout error instead of blocking forever.
- Ensure bridge stop closes client sockets.
- Distinguish invalid input, stale references, conflicts, and operation
  failures.
- Include operation IDs in logs and responses.
- Ensure failed transactions abort and do not leave partial geometry.

## Safety requirements

- Test mode must not weaken authentication.
- Test fixture commands must never accept Ruby source.
- Destructive fixture reset requires an explicit test-only confirmation.
- Smoke tests must use a disposable model or a saved backup.

## Acceptance criteria

- The extension loads without errors on Windows and macOS.
- The bridge accepts authenticated requests and rejects invalid tokens.
- Every existing MCP tool has one passing runtime case.
- Invalid arguments produce structured errors.
- A failed operation leaves the model unchanged.
- A preview does not modify the model.
- An executed operation can be verified and undone.
- The smoke test exits nonzero on any failure.

## Dependencies

None. This phase is a prerequisite for all later feature phases.
