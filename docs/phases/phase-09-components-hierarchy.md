# Phase 9: Components and Hierarchy

## Objective

Allow the AI to understand and safely manipulate SketchUp groups, component
definitions, component instances, and nested editing contexts.

## MCP operations

Add tools for:

- `get_entity_hierarchy`
- `get_component_definition`
- `list_component_definitions`
- `create_component_instance`
- `copy_entities`
- `move_entities_to_container`
- `rename_entity`
- `explode_entities`
- `make_unique`
- `set_component_attributes`

## Read behavior

Hierarchy responses must include:

- Opaque entity reference.
- Entity type.
- Name and path from the model root.
- Parent container reference when known.
- Child count and bounded child summaries.
- Component definition identity for instances.
- Bounds and transformation.
- Material and tag information.

Persistent IDs may be returned as diagnostics but must not replace session
references in tool inputs.

## Mutation behavior

- Moving an instance must not silently edit its definition.
- Definition edits must clearly state that all instances may change.
- `make_unique` must be available before instance-specific geometry edits.
- Explode must require preview and confirmation because it changes hierarchy.
- Nested operations must identify the target container explicitly.

## Cycle and size protection

- Enforce maximum traversal depth.
- Enforce maximum entity count per response.
- Track visited definitions to avoid repeated recursive expansion.
- Return truncation metadata.
- Reject operations that exceed configured limits.

## Acceptance criteria

- The AI can inspect a nested model without confusing definitions and
  instances.
- It can copy and rename groups and component instances.
- It can make an instance unique before editing it.
- It can move entities between valid containers.
- Explode is previewable, confirmable, undoable, and tested.
- Shared component definitions are protected from accidental global edits.
