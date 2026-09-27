const EXTENSION_NAME = "webdyne.cloudflare.d1";
const PROTOCOL_VERSION = 1;
const HOST_FUNCTION_NAME = "WebDyne::Cloudflare::D1::Host::call";

function assertBindingName(name) {
  if (!/^[A-Z_][A-Z0-9_]*$/.test(name)) {
    throw new TypeError(`Invalid D1 binding name: ${name}`);
  }
  return name;
}

function isD1Database(value) {
  return value && typeof value.prepare === "function" && typeof value.batch === "function";
}

function bytesToBase64(bytes) {
  let binary = "";
  const view = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  for (let offset = 0; offset < view.length; offset += 0x8000) {
    binary += String.fromCharCode(...view.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}

function base64ToBytes(encoded) {
  const binary = atob(encoded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function decodeParameter(value) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    if (value.type === "blob" && typeof value.base64 === "string") {
      return base64ToBytes(value.base64);
    }
    throw new TypeError("D1 parameters may not contain structured objects");
  }
  if (Array.isArray(value) || value === undefined) {
    throw new TypeError("D1 parameters must be null, strings, numbers, booleans, or blob envelopes");
  }
  return value;
}

function statementRequest(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new TypeError("D1 statement must be an object");
  }
  if (typeof value.sql !== "string" || value.sql.length === 0) {
    throw new TypeError("D1 statement requires a non-empty SQL string");
  }
  if (value.params !== undefined && !Array.isArray(value.params)) {
    throw new TypeError("D1 statement parameters must be an array");
  }
  return { sql: value.sql, params: (value.params ?? []).map(decodeParameter) };
}

function prepareStatement(database, { sql, params }) {
  const statement = database.prepare(sql);
  return params.length > 0 ? statement.bind(...params) : statement;
}

function encodeBlob(value) {
  if (value instanceof ArrayBuffer) {
    return { type: "blob", base64: bytesToBase64(value) };
  }
  if (ArrayBuffer.isView(value)) {
    return { type: "blob", base64: bytesToBase64(new Uint8Array(value.buffer, value.byteOffset, value.byteLength)) };
  }
  if (Array.isArray(value) && value.every((byte) => Number.isInteger(byte) && byte >= 0 && byte <= 255)) {
    return { type: "blob", base64: bytesToBase64(Uint8Array.from(value)) };
  }
  return value;
}

function encodeRow(row) {
  return Object.fromEntries(Object.entries(row).map(([name, value]) => [name, encodeBlob(value)]));
}

function encodeResult(operation, result) {
  if (operation === "run") {
    return {
      ...result,
      results: Array.isArray(result?.results) ? result.results.map(encodeRow) : [],
    };
  }
  if (operation === "first") {
    if (result === null || typeof result !== "object") return result;
    if (Array.isArray(result) || result instanceof ArrayBuffer || ArrayBuffer.isView(result)) {
      return encodeBlob(result);
    }
    return encodeRow(result);
  }
  if (operation === "raw") {
    return result.map((row) => row.map(encodeBlob));
  }
  return result;
}

function errorResponse(error) {
  const cause = error?.cause;
  const code = error?.code ?? cause?.code;
  return {
    ok: false,
    error: {
      name: typeof error?.name === "string" ? error.name : "D1_ERROR",
      message: typeof error?.message === "string" ? error.message : String(error),
      ...(typeof code === "string" || typeof code === "number" ? { code } : {}),
      ...(typeof cause === "string" ? { cause } : cause?.message ? { cause: cause.message } : {}),
    },
  };
}

export function d1BindingNames(value) {
  if (value === undefined || value === null || value === "") return [];
  const names = Array.isArray(value) ? value : String(value).split(",");
  return [...new Set(names
    .map((name) => String(name).trim())
    .filter(Boolean)
    .map(assertBindingName))];
}

export class D1HostBridge {
  #capabilities = new Map();
  #registeredPerls = new WeakSet();
  #tokenFactory;

  constructor({ tokenFactory = () => crypto.randomUUID() } = {}) {
    this.#tokenFactory = tokenFactory;
  }

  attachScope(scope, env, bindingNames) {
    if (!scope || typeof scope !== "object" || Array.isArray(scope)) {
      throw new TypeError("D1 capability requires a PAGI scope object");
    }
    if (scope.extensions === undefined) scope.extensions = {};
    else if (!scope.extensions || typeof scope.extensions !== "object" || Array.isArray(scope.extensions)) {
      throw new TypeError("PAGI scope extensions must be an object");
    }
    const names = d1BindingNames(bindingNames);
    if (names.length === 0) return { release() {} };

    const bindings = new Map();
    for (const name of names) {
      if (!isD1Database(env?.[name])) throw new Error(`Configured D1 binding ${name} is unavailable`);
      bindings.set(name, env[name]);
    }
    if (scope.extensions[EXTENSION_NAME]) throw new Error(`PAGI extension ${EXTENSION_NAME} is already present`);
    const capability = this.#tokenFactory();
    if (typeof capability !== "string" || capability.length < 8 || this.#capabilities.has(capability)) {
      throw new Error("D1 capability token factory returned an invalid or duplicate token");
    }
    this.#capabilities.set(capability, { bindings, sessions: new Map() });
    scope.extensions[EXTENSION_NAME] = {
      version: PROTOCOL_VERSION,
      capability,
      bindings: [...bindings.keys()],
      session_bindings: [...bindings].filter(([, database]) => typeof database.withSession === "function").map(([name]) => name),
    };
    let released = false;
    return {
      capability,
      release: () => {
        if (released) return;
        released = true;
        this.#capabilities.delete(capability);
        if (scope.extensions[EXTENSION_NAME]?.capability === capability) {
          delete scope.extensions[EXTENSION_NAME];
        }
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
        response = errorResponse(error);
      }
      return perl.createString(JSON.stringify(response));
    });
    this.#registeredPerls.add(perl);
  }

  async dispatch(request) {
    if (!request || typeof request !== "object" || Array.isArray(request)) {
      throw new TypeError("D1 host request must be an object");
    }
    if (request.version !== PROTOCOL_VERSION) throw new Error("Unsupported D1 host protocol");
    const state = this.#capabilities.get(request.capability);
    if (!state) throw new Error("D1 capability is invalid or has expired");
    let database = state.bindings.get(assertBindingName(request.binding));
    if (!database) throw new Error(`D1 binding ${request.binding} is not allowed by this capability`);
    if (request.operation === "with_session") {
      if (request.session !== undefined) throw new TypeError("Cannot create a session from a session");
      if (typeof database.withSession !== "function") throw new Error("D1 Sessions API is unavailable for this binding");
      if (request.constraint !== undefined && (typeof request.constraint !== "string" || request.constraint.length === 0)) {
        throw new TypeError("D1 session requires a non-empty constraint or bookmark");
      }
      const session = database.withSession(request.constraint ?? "first-unconstrained");
      if (!isD1Database(session) || typeof session.getBookmark !== "function") throw new Error("Invalid D1 session provider");
      const id = crypto.randomUUID();
      state.sessions.set(id, { binding: request.binding, database: session });
      return id;
    }
    if (request.session !== undefined) {
      const session = state.sessions.get(request.session);
      if (!session || session.binding !== request.binding) throw new Error("D1 session is invalid or belongs to another binding or request");
      database = session.database;
    }
    if (request.operation === "get_bookmark") {
      if (request.session === undefined) throw new Error("D1 bookmark requires a session");
      return database.getBookmark();
    }
    if (request.operation === "batch") {
      if (!Array.isArray(request.statements) || request.statements.length === 0) {
        throw new TypeError("D1 batch requires a non-empty array of statements");
      }
      // Decode the entire batch before preparing or executing provider statements.
      const requests = request.statements.map(statementRequest);
      const statements = requests.map((value) => prepareStatement(database, value));
      const results = await database.batch(statements);
      return results.map((result) => encodeResult("run", result));
    }
    const statement = prepareStatement(database, statementRequest(request));

    let result;
    if (request.operation === "run") result = await statement.run();
    else if (request.operation === "first") {
      result = request.column === undefined
        ? await statement.first()
        : await statement.first(request.column);
    }
    else if (request.operation === "raw") {
      result = await statement.raw({ columnNames: request.column_names === true });
    }
    else throw new Error(`Unsupported D1 operation: ${request.operation}`);
    return encodeResult(request.operation, result);
  }
}

export { EXTENSION_NAME as D1_EXTENSION_NAME, HOST_FUNCTION_NAME as D1_HOST_FUNCTION_NAME };
