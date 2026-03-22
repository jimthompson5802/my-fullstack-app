export type Operation = "add" | "subtract" | "multiply" | "divide";

export interface ComputeRequest {
  x: string;
  y: string;
  op: Operation;
}

export interface ComputeResponse {
  result: string;
}

export interface ErrorResponse {
  error: string;
  code: string;
  details?: Record<string, string>;
}
