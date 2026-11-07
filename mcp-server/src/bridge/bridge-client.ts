import { randomUUID } from "node:crypto";
import { createConnection, type Socket } from "node:net";
import {
  DEFAULT_TIMEOUT_MS,
  PROTOCOL_VERSION,
  type BridgeRequest,
  type BridgeResponse,
} from "../protocol/types.js";

export class BridgeClient {
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
