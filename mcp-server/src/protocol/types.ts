export const PROTOCOL_VERSION = 1;
export const DEFAULT_HOST = "127.0.0.1";
export const DEFAULT_PORT = 43821;
export const DEFAULT_TIMEOUT_MS = 10_000;

export interface BridgeError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface BridgeSuccessResponse {
  protocol_version: number;
  request_id: string;
  success: true;
  result: Record<string, unknown>;
}

export interface BridgeFailureResponse {
  protocol_version: number;
  request_id: string;
  success: false;
  error: BridgeError;
}

export type BridgeResponse = BridgeSuccessResponse | BridgeFailureResponse;

export interface BridgeRequest {
  protocol_version: number;
  request_id: string;
  operation: string;
  auth_token: string;
  arguments: Record<string, unknown>;
}
