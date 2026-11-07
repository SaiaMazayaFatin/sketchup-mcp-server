import { randomUUID } from "node:crypto";
import { createConnection, type Socket } from "node:net";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const PROTOCOL_VERSION = 1;
const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 43821;
const DEFAULT_TIMEOUT_MS = 10_000;

type BridgeErrorCode =
  | "INVALID_ENVELOPE"
  | "UNSUPPORTED_PROTOCOL"
  | "UNAUTHENTICATED"
  | "NOT_CONNECTED"
  | "OPERATION_TIMEOUT"
  | "INTERNAL_ERROR";

interface BridgeError {
  code: BridgeErrorCode | string;
  message: string;
  details?: Record<string, unknown>;
}

interface BridgeSuccessResponse {
  protocol_version: number;
  request_id: string;
  success: true;
  result: Record<string, unknown>;
}

interface BridgeFailureResponse {
  protocol_version: number;
  request_id: string;
  success: false;
  error: BridgeError;
}

type BridgeResponse = BridgeSuccessResponse | BridgeFailureResponse;

interface BridgeRequest {
  protocol_version: number;
  request_id: string;
  operation: string;
  auth_token: string;
  arguments: Record<string, unknown>;
}

const inspectionTools = [
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

const geometryTools = [
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

class BridgeClient {
  private socket: Socket | undefined;
  private buffer = "";
  private readonly pending = new Map<
    string,
    {
      resolve: (response: BridgeResponse) => void;
      reject: (error: Error) => void;
      timer: NodeJS.Timeout;
    }
  >();

  constructor(
    private readonly host: string,
    private readonly port: number,
    private readonly token: string,
  ) {}

  async request(
    operation: string,
    args: Record<string, unknown> = {},
  ): Promise<Record<string, unknown>> {
    const socket = await this.connect();
    const requestId = `req_${randomUUID()}`;
    const request: BridgeRequest = {
      protocol_version: PROTOCOL_VERSION,
      request_id: requestId,
      operation,
      auth_token: this.token,
      arguments: args,
    };

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(requestId);
        reject(new Error(`Bridge request timed out: ${operation}`));
      }, DEFAULT_TIMEOUT_MS);
      this.pending.set(requestId, {
        timer,
        resolve: (response) => {
          if (response.success) {
            resolve(response.result);
          } else {
            reject(new Error(`${response.error.code}: ${response.error.message}`));
          }
        },
        reject,
      });
      socket.write(`${JSON.stringify(request)}\n`, "utf8");
    });
  }

  close(): void {
    this.rejectPending(new Error("Bridge connection closed"));
    this.socket?.destroy();
    this.socket = undefined;
  }

  private connect(): Promise<Socket> {
    if (this.socket && !this.socket.destroyed) {
      return Promise.resolve(this.socket);
    }

    return new Promise((resolve, reject) => {
      const socket = createConnection({ host: this.host, port: this.port });
      const onError = (error: Error) => {
        socket.destroy();
        reject(new Error(`Unable to connect to SketchUp bridge: ${error.message}`));
      };
      socket.once("connect", () => {
        socket.removeListener("error", onError);
        this.socket = socket;
        this.configureSocket(socket);
        resolve(socket);
      });
      socket.once("error", onError);
    });
  }

  private configureSocket(socket: Socket): void {
    socket.setEncoding("utf8");
    socket.on("data", (chunk: string) => this.receive(chunk));
    socket.on("error", (error) => this.rejectPending(error));
    socket.on("close", () => {
      this.socket = undefined;
      this.rejectPending(new Error("SketchUp bridge disconnected"));
    });
  }

  private receive(chunk: string): void {
    this.buffer += chunk;
    let newlineIndex = this.buffer.indexOf("\n");
    while (newlineIndex >= 0) {
      const line = this.buffer.slice(0, newlineIndex).trim();
      this.buffer = this.buffer.slice(newlineIndex + 1);
      if (line.length > 0) {
        this.resolveLine(line);
      }
      newlineIndex = this.buffer.indexOf("\n");
    }
  }

  private resolveLine(line: string): void {
    let response: BridgeResponse;
    try {
      response = JSON.parse(line) as BridgeResponse;
    } catch {
      return;
    }
    if (typeof response.request_id !== "string") {
      return;
    }
    const pending = this.pending.get(response.request_id);
    if (!pending) {
      return;
    }
    clearTimeout(pending.timer);
    this.pending.delete(response.request_id);
    pending.resolve(response);
  }

  private rejectPending(error: Error): void {
    for (const [requestId, pending] of this.pending) {
      clearTimeout(pending.timer);
      this.pending.delete(requestId);
      pending.reject(error);
    }
  }
}

function logError(message: string): void {
  process.stderr.write(`[sketchup-mcp] ${message}\n`);
}

function textResult(value: unknown) {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(value, null, 2),
      },
    ],
  };
}

const host = process.env.SKETCHUP_BRIDGE_HOST ?? DEFAULT_HOST;
const port = Number(process.env.SKETCHUP_BRIDGE_PORT ?? DEFAULT_PORT);
const token = process.env.SKETCHUP_BRIDGE_TOKEN;

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("SKETCHUP_BRIDGE_PORT must be a valid TCP port");
}
if (!token || token.length < 16) {
  throw new Error("SKETCHUP_BRIDGE_TOKEN must contain at least 16 characters");
}

const bridge = new BridgeClient(host, port, token);
const server = new Server(
  {
    name: "sketchup-mcp",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "ping_sketchup",
      description: "Check whether the local SketchUp bridge is reachable.",
      inputSchema: {
        type: "object",
        properties: {},
        additionalProperties: false,
      },
    },
    {
      name: "get_sketchup_status",
      description: "Return SketchUp version, model, platform, and connection status.",
      inputSchema: {
        type: "object",
        properties: {},
        additionalProperties: false,
      },
    },
    ...inspectionTools,
    ...geometryTools,
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const toolName = request.params.name;
  const knownTools = new Set([
    "ping_sketchup",
    "get_sketchup_status",
    ...inspectionTools.map((tool) => tool.name),
    ...geometryTools.map((tool) => tool.name),
  ]);
  if (!knownTools.has(toolName)) {
    return {
      isError: true,
      content: [{ type: "text", text: `Unknown tool: ${toolName}` }],
    };
  }

  try {
    const operation = toolName;
    const args = request.params.arguments;
    const result = await bridge.request(
      operation,
      args && typeof args === "object" ? args as Record<string, unknown> : {},
    );
    return textResult(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logError(`${toolName}: ${message}`);
    return {
      isError: true,
      content: [{ type: "text", text: message }],
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);

const shutdown = async () => {
  bridge.close();
  await server.close();
};

process.once("SIGINT", () => {
  void shutdown().catch((error) => logError(String(error)));
});
process.once("SIGTERM", () => {
  void shutdown().catch((error) => logError(String(error)));
});