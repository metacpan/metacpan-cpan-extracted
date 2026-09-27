import { storageBindingNames, scopeExtensions, createCapability } from "./storage-host.js";
import { encodeValue, decodeValue, wire, methodName, errorResponse, MAX_WIRE_BYTES } from "./durable-object-codec.js";

export const DURABLE_OBJECT_EXTENSION = "webdyne.cloudflare.durable_object";
export const durableObjectBindingNames = value => storageBindingNames(value, "Durable Object");

export class DurableObjectHostBridge {
  #capabilities = new Map();
  #registered = new WeakSet();
  constructor({ nativeBindings = [] } = {}) {
    this.nativeBindings = new Set(durableObjectBindingNames(nativeBindings));
  }
  register(perl) {
    if (this.#registered.has(perl)) return;
    perl.registerFunction("WebDyne::Cloudflare::DurableObject::Host::call", async request => {
      let response;
      try {
        const text = request.toString();
        if (new TextEncoder().encode(text).byteLength > MAX_WIRE_BYTES) throw new RangeError("Durable Object request exceeds 1 MiB");
        response = { ok: true, result: await this.dispatch(JSON.parse(text)) };
        wire(response);
      } catch (error) { response = errorResponse(error); }
      return perl.createString(wire(response));
    });
    this.#registered.add(perl);
  }
  attachScope(scope, env, names, invocation) {
    const bindings = new Map();
    for (const name of durableObjectBindingNames(names)) {
      if (!env?.[name] || typeof env[name].idFromName !== "function" || typeof env[name].get !== "function") {
        throw new Error(`Configured Durable Object binding ${name} is unavailable`);
      }
      bindings.set(name, env[name]);
    }
    if (!bindings.size && !invocation?.durableObject) return { release() {} };
    const extensions = scopeExtensions(scope, "Durable Object");
    if (extensions[DURABLE_OBJECT_EXTENSION]) throw new Error("Duplicate Durable Object capability");
    const capability = createCapability(this.#capabilities, () => crypto.randomUUID(), "Durable Object");
    this.#capabilities.set(capability, { bindings, object: invocation?.durableObject });
    extensions[DURABLE_OBJECT_EXTENSION] = { version: 1, capability, bindings: [...bindings.keys()],
      ...(invocation?.durableObject ? { id: invocation.durableObject.id } : {}) };
    return { release: () => { this.#capabilities.delete(capability); } };
  }
  async dispatch(request) {
    if (request?.version !== 1) throw new TypeError("Unsupported Durable Object protocol");
    const state = this.#capabilities.get(request.capability);
    if (!state) throw new Error("Durable Object capability is invalid or expired");
    if (["sql", "batch"].includes(request.operation)) {
      if (!state.object) throw new Error("Storage is only available inside the owning Durable Object");
      const statements = request.operation === "batch" ? request.statements : [request.statement];
      if (!Array.isArray(statements) || !statements.length || statements.length > 100) throw new TypeError("Expected 1 to 100 SQL statements");
      const decoded = statements.map(statement => {
        if (typeof statement?.sql !== "string" || !statement.sql.trim()
          || new TextEncoder().encode(statement.sql).length > 100000) throw new TypeError("Invalid SQL statement");
        const params = decodeValue(statement.params);
        if (!Array.isArray(params) || params.length > 100 || params.some(value => value !== null
          && typeof value !== "string" && typeof value !== "number" && !(value instanceof ArrayBuffer))) {
          throw new TypeError("SQL bindings must be text, numbers, null or explicit bytes");
        }
        return { sql: statement.sql, params };
      });
      const execute = () => {
        const result = decoded.map(({ sql, params }) => {
          const cursor = state.object.storage.sql.exec(sql, ...params);
          const rows = [];
          let bytes = 0;
          for (const row of cursor) {
            if (rows.length >= 10000) throw new RangeError("SQL result exceeds 10000 rows");
            const encoded = encodeValue(row);
            bytes += new TextEncoder().encode(wire(encoded)).length;
            if (bytes > 1024 * 1024) throw new RangeError("SQL result exceeds 1 MiB");
            rows.push(row);
          }
          return { rows, rows_read: cursor.rowsRead, rows_written: cursor.rowsWritten };
        });
        const encoded = encodeValue(request.operation === "batch" ? result : result[0]);
        wire({ ok: true, result: encoded }); // Check the complete response before committing.
        return encoded;
      };
      // Even a single operation rolls back when encoding or result bounds fail.
      return state.object.storage.transactionSync(execute);
    }
    const namespace = state.bindings.get(request.binding);
    if (!namespace) throw new Error("Durable Object binding is not allowed");
    if (request.operation === "resolve") {
      if (typeof request.name !== "string" || !request.name.length) throw new TypeError("Object name must be non-empty text");
      return namespace.idFromName(request.name).toString();
    }
    if (typeof request.id !== "string") throw new TypeError("Object ID must be text");
    const id = namespace.idFromString(request.id);
    if (request.operation === "validate_id") return id.toString();
    if (request.operation !== "call") throw new TypeError("Unknown Durable Object operation");
    const method = methodName(request.method);
    const chain = state.object?.chain ?? [];
    if (chain.includes(id.toString())) throw new Error("Durable Object call cycle or same-object re-entry rejected");
    if (chain.length >= 32) throw new Error("Durable Object call depth exceeds 32");
    const stub = namespace.get(id);
    if (this.nativeBindings.has(request.binding)) {
      const args = decodeValue(request.args);
      if (!Array.isArray(args)) throw new TypeError("RPC arguments must be an array");
      return encodeValue(await stub[method](...args));
    }
    // Framework calls carry ancestry, including across Workers and binding aliases.
    const response = await stub.webdyneInvoke({ version: 1, method, args: request.args, chain });
    wire(response);
    if (!response || typeof response.ok !== "boolean") throw new Error("Invalid Durable Object RPC response");
    if (!response.ok) {
      const error = new Error(response.error?.message ?? "Durable Object RPC failed");
      error.name = response.error?.name ?? "DURABLE_OBJECT_ERROR";
      error.code = response.error?.code;
      throw error;
    }
    decodeValue(response.result);
    return response.result;
  }
}
