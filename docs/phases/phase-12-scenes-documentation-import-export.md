# Phase 12: Scenes, Documentation, and Import/Export

## Objective

Expand presentation and exchange workflows after core modeling and automation
are reliable.

## Scenes and views

Add controlled operations for:

- Scene update and deletion.
- Scene ordering.
- Camera projection and field of view.
- Section planes.
- Tag visibility per scene.
- Shadow and environment settings.
- Style selection and inspection.
- Animation playback metadata.

Every view operation must clearly identify whether it changes the model file,
the active view only, or a scene.

## Documentation

Add:

- Dimensions.
- 2D text.
- Leader labels.
- Guides.
- Axes inspection and controlled updates.
- Annotation listing and deletion.

Documentation operations must use explicit coordinates, units, text, and
association references. Deletion requires preview and confirmation.

## Import and export

Start with safe, bounded workflows:

- Import an image from an approved local path.
- Import a supported model format from an approved local path.
- Export a model or scene to an approved local path.
- List supported formats and capability status.

## Path and file safety

- Never accept remote URLs by default.
- Restrict paths to user-approved directories.
- Reject path traversal and ambiguous paths.
- Do not overwrite an existing file without explicit confirmation.
- Return the exact output path and file size.
- Report unsupported formats explicitly.

## Acceptance criteria

- Scene/view changes are distinguishable and reversible where SketchUp allows.
- Dimensions and labels can be created, inspected, and removed.
- Imports and exports work on documented formats.
- File operations pass path and overwrite safety checks.
- Runtime tests cover failures such as missing files and unsupported formats.
