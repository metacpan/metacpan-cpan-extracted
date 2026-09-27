import { bytesToBase64, base64ToBytes } from "./storage-host.js";

export const MAX_WIRE_BYTES = 1024 * 1024;

/** Tagged containers make byte values unambiguous even in arbitrary user hashes. */
export function encodeValue(value, seen = new Set(), depth = 0) {
  if (depth > 64) throw new RangeError("Durable Object value nesting exceeds 64");
  if (value === null || typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)
    && (!Number.isInteger(value) || Number.isSafeInteger(value))) return value;
  if (value instanceof ArrayBuffer || ArrayBuffer.isView(value)) {
    const bytes = value instanceof ArrayBuffer ? new Uint8Array(value)
      : new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
    if (bytes.byteLength > MAX_WIRE_BYTES) throw new RangeError("Durable Object bytes exceed limit");
    return { t: "bytes", v: bytesToBase64(bytes) };
  }
  if (!value || typeof value !== "object" || seen.has(value)) throw new TypeError("Unsupported or cyclic Durable Object value");
  seen.add(value);
  try {
    if (Array.isArray(value)) return { t: "array", v: value.map(item => encodeValue(item, seen, depth + 1)) };
    if (![Object.prototype, null].includes(Object.getPrototypeOf(value))) throw new TypeError("Durable Object values must be plain objects");
    return { t: "hash", v: Object.fromEntries(Object.entries(value).map(([key, item]) => [key, encodeValue(item, seen, depth + 1)])) };
  } finally { seen.delete(value); }
}

export function decodeValue(value, depth = 0) {
  if (depth > 64) throw new RangeError("Durable Object value nesting exceeds 64");
  if (value === null || typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number") return encodeValue(value);
  if (!value || typeof value !== "object" || Array.isArray(value)
    || Object.keys(value).length !== 2) throw new TypeError("Invalid Durable Object value envelope");
  if (value.t === "bytes" && typeof value.v === "string" && /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value.v)) {
    if (value.v.length > Math.ceil(MAX_WIRE_BYTES / 3) * 4) throw new RangeError("Durable Object bytes exceed limit");
    return base64ToBytes(value.v).buffer;
  }
  if (value.t === "array" && Array.isArray(value.v)) return value.v.map(item => decodeValue(item, depth + 1));
  if (value.t === "hash" && value.v && typeof value.v === "object" && !Array.isArray(value.v)) {
    return Object.fromEntries(Object.entries(value.v).map(([key, item]) => [key, decodeValue(item, depth + 1)]));
  }
  throw new TypeError("Invalid Durable Object value envelope");
}

export function wire(value) {
  const result = JSON.stringify(value);
  if (new TextEncoder().encode(result).byteLength > MAX_WIRE_BYTES) throw new RangeError("Durable Object message exceeds 1 MiB");
  return result;
}

export function methodName(value) {
  if (typeof value !== "string" || !/^[a-zA-Z][a-zA-Z0-9_]*$/.test(value)
    || ["constructor", "prototype", "then", "fetch", "alarm", "webSocketMessage", "webSocketClose", "webSocketError", "webdyneInvoke", "initialize", "DESTROY", "AUTOLOAD"].includes(value)) {
    throw new TypeError("Invalid or reserved Durable Object RPC method");
  }
  return value;
}

/** Error envelopes remain bounded even when a remote service returns a huge message. */
export function errorResponse(error) {
  return { ok: false, error: {
    name: String(error?.name ?? "DURABLE_OBJECT_ERROR").slice(0, 128),
    message: String(error?.message ?? error).slice(0, 4096),
    ...(["string", "number"].includes(typeof error?.code) ? { code: String(error.code).slice(0, 128) } : {}),
  } };
}
