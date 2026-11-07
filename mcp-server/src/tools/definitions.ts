export const inspectionTools = [
  {
    name: "get_model_summary",
    description: "Return bounded metadata, units, counts, bounds, and model resources.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "get_model_units",
    description: "Return the active SketchUp model unit settings.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "get_selection",
    description: "Return the currently selected SketchUp entities.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "get_entity_details",
    description: "Return details for a session-scoped entity reference.",
    inputSchema: {
      type: "object",
      properties: { entity_ref: { type: "string", minLength: 1 } },
      required: ["entity_ref"],
      additionalProperties: false,
    },
  },
  {
    name: "list_entities",
    description: "Return a bounded page of top-level model entities.",
    inputSchema: {
      type: "object",
      properties: {
        limit: { type: "integer", minimum: 1, maximum: 500 },
        offset: { type: "integer", minimum: 0 },
        entity_types: { type: "array", items: { type: "string" }, uniqueItems: true },
      },
      additionalProperties: false,
    },
  },
  {
    name: "list_materials",
    description: "List materials in the active SketchUp model.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "list_tags",
    description: "List tags in the active SketchUp model.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "list_scenes",
    description: "List scenes in the active SketchUp model.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
] as const;

export const geometryTools = [
  {
    name: "create_box",
    description: "Create a grouped box using explicit length units.",
    inputSchema: {
      type: "object",
      required: ["origin", "width", "depth", "height"],
      properties: {
        origin: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
        origin_unit: { type: "string", enum: ["mm", "cm", "m", "in", "ft"], default: "mm" },
        width: { type: "object" },
        depth: { type: "object" },
        height: { type: "object" },
        name: { type: "string", minLength: 1 },
      },
      additionalProperties: false,
    },
  },
  {
    name: "create_cylinder",
    description: "Create a grouped cylinder using explicit length units.",
    inputSchema: {
      type: "object",
      required: ["center", "radius", "height"],
      properties: {
        center: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
        center_unit: { type: "string", enum: ["mm", "cm", "m", "in", "ft"], default: "mm" },
        radius: { type: "object" },
        height: { type: "object" },
        segments: { type: "integer", minimum: 3, maximum: 256 },
        name: { type: "string", minLength: 1 },
      },
      additionalProperties: false,
    },
  },
  {
    name: "create_group",
    description: "Create an empty top-level group.",
    inputSchema: {
      type: "object",
      properties: { name: { type: "string", minLength: 1 } },
      additionalProperties: false,
    },
  },
  {
    name: "transform_entities",
    description: "Translate session-scoped entities by an explicit vector.",
    inputSchema: {
      type: "object",
      required: ["entity_refs", "translation"],
      properties: {
        entity_refs: { type: "array", minItems: 1, items: { type: "string" }, uniqueItems: true },
        translation: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
        translation_unit: { type: "string", enum: ["mm", "cm", "m", "in", "ft"], default: "mm" },
      },
      additionalProperties: false,
    },
  },
  {
    name: "delete_entities",
    description: "Delete entities after explicit confirmation.",
    inputSchema: {
      type: "object",
      required: ["entity_refs", "confirm"],
      properties: {
        entity_refs: { type: "array", minItems: 1, items: { type: "string" }, uniqueItems: true },
        confirm: { type: "boolean", const: true },
      },
      additionalProperties: false,
    },
  },
] as const;

export const presentationTools = [
  {
    name: "apply_material",
    description: "Apply an existing material to a referenced entity.",
    inputSchema: {
      type: "object",
      required: ["entity_ref", "material_name"],
      properties: {
        entity_ref: { type: "string", minLength: 1 },
        material_name: { type: "string", minLength: 1 },
      },
      additionalProperties: false,
    },
  },
  {
    name: "set_entity_tag",
    description: "Assign an existing tag to a referenced entity.",
    inputSchema: {
      type: "object",
      required: ["entity_ref", "tag_name"],
      properties: {
        entity_ref: { type: "string", minLength: 1 },
        tag_name: { type: "string", minLength: 1 },
      },
      additionalProperties: false,
    },
  },
  {
    name: "get_active_view",
    description: "Return the active SketchUp camera and viewport.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "create_scene",
    description: "Create a named scene from the current view.",
    inputSchema: {
      type: "object",
      required: ["name"],
      properties: { name: { type: "string", minLength: 1 } },
      additionalProperties: false,
    },
  },
  {
    name: "set_camera",
    description: "Set the active SketchUp camera using position, target, and up vectors.",
    inputSchema: {
      type: "object",
      required: ["position", "target"],
      properties: {
        position: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
        target: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
        up: { type: "array", prefixItems: [{ type: "number" }, { type: "number" }, { type: "number" }], items: false },
      },
      additionalProperties: false,
    },
  },
] as const;

export const operationTools = [
  {
    name: "preview_operation",
    description: "Preview a write operation without changing the model.",
    inputSchema: {
      type: "object",
      required: ["operation", "arguments"],
      properties: {
        operation: { type: "string", minLength: 1 },
        arguments: { type: "object" },
      },
      additionalProperties: false,
    },
  },
  {
    name: "execute_operation",
    description: "Execute a valid preview; destructive previews require confirm=true.",
    inputSchema: {
      type: "object",
      required: ["preview_id"],
      properties: {
        preview_id: { type: "string", minLength: 1 },
        confirm: { type: "boolean" },
      },
      additionalProperties: false,
    },
  },
  {
    name: "undo_last_operation",
    description: "Undo the last completed SketchUp operation.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
] as const;

export const connectionTools = [
  {
    name: "ping_sketchup",
    description: "Check whether the local SketchUp bridge is reachable.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "get_sketchup_status",
    description: "Return SketchUp version, model, platform, and connection status.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
] as const;

export const allTools = [
  ...connectionTools,
  ...inspectionTools,
  ...geometryTools,
  ...presentationTools,
  ...operationTools,
];

export const toolNames: Set<string> = new Set(allTools.map((tool) => tool.name));
