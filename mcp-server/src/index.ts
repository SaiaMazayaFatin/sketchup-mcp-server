import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { BridgeClient } from "./bridge/bridge-client.js";
import {
  DEFAULT_HOST,
  DEFAULT_PORT,
} from "./protocol/types.js";
import { allTools, toolNames } from "./tools/definitions.js";

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
  tools: allTools,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const toolName = request.params.name;
  if (!toolNames.has(toolName)) {
    return {
      isError: true,
      content: [{ type: "text", text: `Unknown tool: ${toolName}` }],
    };
  }

  try {
    const args = request.params.arguments;
    const result = await bridge.request(
      toolName,
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
