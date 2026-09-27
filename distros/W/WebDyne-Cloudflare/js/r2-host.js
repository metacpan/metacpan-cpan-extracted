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

const EXTENSION_NAME = "webdyne.cloudflare.r2";
const PROTOCOL_VERSION = 1;
const HOST_FUNCTION_NAME = "WebDyne::Cloudflare::R2::Host::call";
const DEFAULT_MAX_OBJECT_BYTES = 16 * 1024 * 1024;

function isR2Bucket(value) {
  return value
    && typeof value.get === "function"
    && typeof value.head === "function"
    && typeof value.put === "function"
    && typeof value.delete === "function"
    && typeof value.list === "function";
}

function key(value) {
  if (typeof value !== "string" || value.length === 0) throw new TypeError("R2 key must be a non-empty string");
  return value;
}

function serializedHttpMetadata(value = {}) {
  return {
    ...(value.contentType === undefined ? {} : { content_type: value.contentType }),
    ...(value.contentLanguage === undefined ? {} : { content_language: value.contentLanguage }),
    ...(value.contentDisposition === undefined ? {} : { content_disposition: value.contentDisposition }),
    ...(value.contentEncoding === undefined ? {} : { content_encoding: value.contentEncoding }),
    ...(value.cacheControl === undefined ? {} : { cache_control: value.cacheControl }),
    ...(value.cacheExpiry === undefined ? {} : {
      cache_expiry: value.cacheExpiry instanceof Date ? value.cacheExpiry.toISOString() : value.cacheExpiry,
    }),
  };
}

function objectMetadata(object) {
  if (object === null) return null;
  return {
    key: object.key,
    version: object.version,
    size: object.size,
    etag: object.etag,
    http_etag: object.httpEtag,
    uploaded: object.uploaded instanceof Date ? object.uploaded.toISOString() : object.uploaded,
    http_metadata: serializedHttpMetadata(object.httpMetadata),
    custom_metadata: object.customMetadata ?? {},
    storage_class: object.storageClass,
    ...(object.range === undefined ? {} : { range: object.range }),
  };
}

function getOptions(request) {
  if (request.range === undefined) return {};
  const range = plainObject(request.range, "R2 range");
  if (range.suffix !== undefined) {
    return { range: { suffix: positiveInteger(range.suffix, "R2 range suffix") } };
  }
  const offset = positiveInteger(range.offset, "R2 range offset", { minimum: 0 });
  return {
    range: {
      offset,
      ...(range.length === undefined ? {} : { length: positiveInteger(range.length, "R2 range length") }),
    },
  };
}

function httpMetadata(value) {
  if (value === undefined) return undefined;
  const metadata = plainObject(value, "R2 http_metadata");
  const names = {
    content_type: "contentType",
    content_language: "contentLanguage",
    content_disposition: "contentDisposition",
    content_encoding: "contentEncoding",
    cache_control: "cacheControl",
  };
  const result = {};
  for (const [source, destination] of Object.entries(names)) {
    if (metadata[source] !== undefined) result[destination] = String(metadata[source]);
  }
  if (metadata.cache_expiry !== undefined) {
    const date = new Date(metadata.cache_expiry);
    if (Number.isNaN(date.getTime())) throw new TypeError("R2 cache_expiry must be an ISO date");
    result.cacheExpiry = date;
  }
  return result;
}

function writeOptions(request) {
  const result = {};
  const http = httpMetadata(request.http_metadata);
  if (http !== undefined) result.httpMetadata = http;
  if (request.custom_metadata !== undefined) {
    const metadata = plainObject(request.custom_metadata, "R2 custom_metadata");
    result.customMetadata = Object.fromEntries(
      Object.entries(metadata).map(([name, value]) => [name, String(value)]),
    );
  }
  if (request.storage_class !== undefined) result.storageClass = String(request.storage_class);
  return result;
}

function listOptions(request) {
  const include = request.include;
  if (include !== undefined && (!Array.isArray(include)
    || include.some((name) => !["httpMetadata", "customMetadata"].includes(name)))) {
    throw new TypeError("R2 list include must contain only httpMetadata or customMetadata");
  }
  return {
    ...(request.prefix === undefined ? {} : { prefix: String(request.prefix) }),
    ...(request.cursor === undefined ? {} : { cursor: String(request.cursor) }),
    ...(request.delimiter === undefined ? {} : { delimiter: String(request.delimiter) }),
    ...(request.limit === undefined
      ? {}
      : { limit: positiveInteger(request.limit, "R2 list limit", { maximum: 1000 }) }),
    ...(include === undefined ? {} : { include }),
  };
}

export function r2BindingNames(value) {
  return storageBindingNames(value, "R2");
}

export class R2HostBridge {
  #capabilities = new Map();
  #registeredPerls = new WeakSet();
  #tokenFactory;
  #maxObjectBytes;

  constructor({
    tokenFactory = () => crypto.randomUUID(),
    maxObjectBytes = DEFAULT_MAX_OBJECT_BYTES,
  } = {}) {
    this.#tokenFactory = tokenFactory;
    this.#maxObjectBytes = positiveInteger(maxObjectBytes, "R2 maxObjectBytes");
  }

  attachScope(scope, env, bindingNames) {
    const extensions = scopeExtensions(scope, "R2");
    const names = r2BindingNames(bindingNames);
    if (names.length === 0) return { release() {} };

    const bindings = new Map();
    for (const name of names) {
      if (!isR2Bucket(env?.[name])) throw new Error(`Configured R2 binding ${name} is unavailable`);
      bindings.set(name, env[name]);
    }
    if (extensions[EXTENSION_NAME]) throw new Error(`PAGI extension ${EXTENSION_NAME} is already present`);
    const capability = createCapability(this.#capabilities, this.#tokenFactory, "R2");
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

  register(perl) {
    if (this.#registeredPerls.has(perl)) return;
    perl.registerFunction(HOST_FUNCTION_NAME, async (requestValue) => {
      let response;
      try {
        response = { ok: true, result: await this.dispatch(JSON.parse(requestValue.toString())) };
      } catch (error) {
        response = storageErrorResponse(error, "R2_ERROR");
      }
      return perl.createString(JSON.stringify(response));
    });
    this.#registeredPerls.add(perl);
  }

  async dispatch(request) {
    if (!request || typeof request !== "object" || Array.isArray(request)) {
      throw new TypeError("R2 host request must be an object");
    }
    if (request.version !== PROTOCOL_VERSION) throw new Error("Unsupported R2 host protocol");
    const bindings = this.#capabilities.get(request.capability);
    if (!bindings) throw new Error("R2 capability is invalid or has expired");
    const bucket = bindings.get(r2BindingNames([request.binding])[0]);
    if (!bucket) throw new Error(`R2 binding ${request.binding} is not allowed by this capability`);

    if (request.operation === "get") {
      const object = await bucket.get(key(request.key), getOptions(request));
      if (object === null) return null;
      if (object.body === undefined || typeof object.arrayBuffer !== "function") {
        return objectMetadata(object);
      }
      const returnedSize = object.range?.length ?? object.size;
      if (returnedSize > this.#maxObjectBytes) {
        if (typeof object.body?.cancel === "function") await object.body.cancel();
        throw new RangeError("R2 object exceeds the configured byte limit");
      }
      const body = await object.arrayBuffer();
      if (body.byteLength > this.#maxObjectBytes) throw new RangeError("R2 object exceeds the configured byte limit");
      return { ...objectMetadata(object), body: encodeBytes(body) };
    }
    if (request.operation === "head") return objectMetadata(await bucket.head(key(request.key)));
    if (request.operation === "put") {
      let value = request.value;
      if (typeof value === "string") {
        if (new TextEncoder().encode(value).byteLength > this.#maxObjectBytes) {
          throw new RangeError("R2 object exceeds the configured byte limit");
        }
      } else {
        value = decodeBytes(value, "R2 object", this.#maxObjectBytes);
      }
      return objectMetadata(await bucket.put(key(request.key), value, writeOptions(request)));
    }
    if (request.operation === "delete") {
      if (Array.isArray(request.keys) && (request.keys.length === 0 || request.keys.length > 1000)) {
        throw new RangeError("R2 multiple delete requires between 1 and 1000 keys");
      }
      const keys = Array.isArray(request.keys) ? request.keys.map(key) : key(request.key);
      await bucket.delete(keys);
      return true;
    }
    if (request.operation === "list") {
      const result = await bucket.list(listOptions(request));
      return {
        objects: (result.objects ?? []).map(objectMetadata),
        truncated: result.truncated === true,
        ...(result.cursor === undefined ? {} : { cursor: result.cursor }),
        delimited_prefixes: result.delimitedPrefixes ?? [],
      };
    }
    throw new Error(`Unsupported R2 operation: ${request.operation}`);
  }
}

export {
  DEFAULT_MAX_OBJECT_BYTES as R2_DEFAULT_MAX_OBJECT_BYTES,
  EXTENSION_NAME as R2_EXTENSION_NAME,
  HOST_FUNCTION_NAME as R2_HOST_FUNCTION_NAME,
};
