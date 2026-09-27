import {
  createCapability,
  decodeBytes,
  encodeBytes,
  plainObject,
  positiveInteger,
  scopeExtensions,
  storageBindingNames,
  storageErrorResponse,
} from "./storage-host.js";

const EXTENSION_NAME = "webdyne.cloudflare.kv";
const PROTOCOL_VERSION = 1;
const HOST_FUNCTION_NAME = "WebDyne::Cloudflare::KV::Host::call";
const DEFAULT_MAX_VALUE_BYTES = 16 * 1024 * 1024;

function isKVNamespace(value) {
  return value
    && typeof value.get === "function"
    && typeof value.getWithMetadata === "function"
    && typeof value.put === "function"
    && typeof value.delete === "function"
    && typeof value.list === "function";
}

function key(value) {
  if (typeof value !== "string" || value.length === 0 || value === "." || value === "..") {
    throw new TypeError("KV key must be a non-empty string other than . or ..");
  }
  if (new TextEncoder().encode(value).byteLength > 512) throw new RangeError("KV key exceeds 512 bytes");
  return value;
}

function readOptions(request) {
  const type = request.type ?? "text";
  if (!["text", "json", "bytes"].includes(type)) throw new TypeError(`Unsupported KV value type: ${type}`);
  return {
    type,
    cloudflare: {
      type: type === "bytes" ? "arrayBuffer" : type,
      ...(request.cache_ttl === undefined
        ? {}
        : { cacheTtl: positiveInteger(request.cache_ttl, "KV cache_ttl", { minimum: 30 }) }),
    },
  };
}

function writeOptions(request) {
  const options = {};
  if (request.expiration !== undefined && request.expiration_ttl !== undefined) {
    throw new TypeError("KV put accepts expiration or expiration_ttl, not both");
  }
  if (request.expiration !== undefined) {
    options.expiration = positiveInteger(request.expiration, "KV expiration");
  }
  if (request.expiration_ttl !== undefined) {
    options.expirationTtl = positiveInteger(request.expiration_ttl, "KV expiration_ttl", { minimum: 60 });
  }
  if (request.metadata !== undefined) options.metadata = plainObject(request.metadata, "KV metadata");
  return options;
}

function listOptions(request) {
  return {
    ...(request.prefix === undefined ? {} : { prefix: String(request.prefix) }),
    ...(request.cursor === undefined ? {} : { cursor: String(request.cursor) }),
    ...(request.limit === undefined
      ? {}
      : { limit: positiveInteger(request.limit, "KV list limit", { maximum: 1000 }) }),
  };
}

export function kvBindingNames(value) {
  return storageBindingNames(value, "KV");
}

export class KVHostBridge {
  #capabilities = new Map();
  #registeredPerls = new WeakSet();
  #tokenFactory;
  #maxValueBytes;

  constructor({
    tokenFactory = () => crypto.randomUUID(),
    maxValueBytes = DEFAULT_MAX_VALUE_BYTES,
  } = {}) {
    this.#tokenFactory = tokenFactory;
    this.#maxValueBytes = positiveInteger(maxValueBytes, "KV maxValueBytes");
  }

  attachScope(scope, env, bindingNames) {
    const extensions = scopeExtensions(scope, "KV");
    const names = kvBindingNames(bindingNames);
    if (names.length === 0) return { release() {} };

    const bindings = new Map();
    for (const name of names) {
      if (!isKVNamespace(env?.[name])) throw new Error(`Configured KV binding ${name} is unavailable`);
      bindings.set(name, env[name]);
    }
    if (extensions[EXTENSION_NAME]) throw new Error(`PAGI extension ${EXTENSION_NAME} is already present`);
    const capability = createCapability(this.#capabilities, this.#tokenFactory, "KV");
    this.#capabilities.set(capability, bindings);
    extensions[EXTENSION_NAME] = { version: PROTOCOL_VERSION, capability, bindings: [...bindings.keys()] };

    let released = false;
    return {
      capability,
      release: () => {
        if (released) return;
        released = true;
        this.#capabilities.delete(capability);
        if (extensions[EXTENSION_NAME]?.capability === capability) delete extensions[EXTENSION_NAME];
      },
    };
  }

  checkReadValue(value, type) {
    if (value === null) return value;
    const size = type === "bytes"
      ? value.byteLength
      : new TextEncoder().encode(type === "json" ? JSON.stringify(value) : value).byteLength;
    if (size > this.#maxValueBytes) throw new RangeError("KV value exceeds the configured byte limit");
    return type === "bytes" ? encodeBytes(value) : value;
  }

  register(perl) {
    if (this.#registeredPerls.has(perl)) return;
    perl.registerFunction(HOST_FUNCTION_NAME, async (requestValue) => {
      let response;
      try {
        response = { ok: true, result: await this.dispatch(JSON.parse(requestValue.toString())) };
      } catch (error) {
        response = storageErrorResponse(error, "KV_ERROR");
      }
      return perl.createString(JSON.stringify(response));
    });
    this.#registeredPerls.add(perl);
  }

  async dispatch(request) {
    if (!request || typeof request !== "object" || Array.isArray(request)) {
      throw new TypeError("KV host request must be an object");
    }
    if (request.version !== PROTOCOL_VERSION) throw new Error("Unsupported KV host protocol");
    const bindings = this.#capabilities.get(request.capability);
    if (!bindings) throw new Error("KV capability is invalid or has expired");
    const namespace = bindings.get(kvBindingNames([request.binding])[0]);
    if (!namespace) throw new Error(`KV binding ${request.binding} is not allowed by this capability`);

    if (request.operation === "get" || request.operation === "get_with_metadata") {
      const options = readOptions(request);
      const result = request.operation === "get"
        ? await namespace.get(key(request.key), options.cloudflare)
        : await namespace.getWithMetadata(key(request.key), options.cloudflare);
      if (request.operation === "get") return this.checkReadValue(result, options.type);
      return result === null ? null : {
        value: this.checkReadValue(result.value, options.type),
        metadata: result.metadata ?? null,
        ...(result.cacheStatus === undefined ? {} : { cache_status: result.cacheStatus }),
      };
    }
    if (request.operation === "put") {
      let value = request.value;
      if (typeof value === "string") {
        if (new TextEncoder().encode(value).byteLength > this.#maxValueBytes) {
          throw new RangeError("KV value exceeds the configured byte limit");
        }
      } else {
        value = decodeBytes(value, "KV value", this.#maxValueBytes);
      }
      await namespace.put(key(request.key), value, writeOptions(request));
      return true;
    }
    if (request.operation === "delete") {
      await namespace.delete(key(request.key));
      return true;
    }
    if (request.operation === "list") return namespace.list(listOptions(request));
    throw new Error(`Unsupported KV operation: ${request.operation}`);
  }
}

export {
  DEFAULT_MAX_VALUE_BYTES as KV_DEFAULT_MAX_VALUE_BYTES,
  EXTENSION_NAME as KV_EXTENSION_NAME,
  HOST_FUNCTION_NAME as KV_HOST_FUNCTION_NAME,
};
