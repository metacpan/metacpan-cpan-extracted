import { protocolError } from "./hyperdrive-codec.js";
import { postgresProtocol } from "./hyperdrive-postgres.js";

export const HYPERDRIVE_EXTENSION_NAME = "webdyne.cloudflare.hyperdrive";
export const HYPERDRIVE_HOST_FUNCTION_NAME = "WebDyne::Cloudflare::Hyperdrive::Transport::host_call";
export const HYPERDRIVE_DEFAULT_LIMITS = Object.freeze({
  maxConnections: 4, maxRequestBytes: 1048576, maxResultBytes: 4194304,
  maxRows: 10000, connectTimeoutMs: 5000, queryTimeoutMs: 10000, cleanupTimeoutMs: 5000,
});

export function hyperdriveBindingNames(value = []) {
  const names = typeof value === "string" ? value.split(/[\s,]+/).filter(Boolean) : value;
  if (!Array.isArray(names) || names.some(name => typeof name !== "string" || !/^[A-Z_][A-Z0-9_]*$/.test(name))) {
    throw new TypeError("Hyperdrive bindings must be an array of binding names");
  }
  return [...new Set(names)];
}

// Remove only leading SQL comments to reject transaction/session control. The
// extended PostgreSQL protocol, rather than a SQL splitter, enforces one statement.
function firstKeyword(sql) {
  let offset = 0;
  for (;;) {
    while (/\s/.test(sql[offset] ?? "") && offset < sql.length) offset++;
    if (sql.startsWith("--", offset)) {
      const end = sql.indexOf("\n", offset + 2);
      offset = end < 0 ? sql.length : end + 1;
    } else if (sql.startsWith("/*", offset)) {
      let depth = 1;
      offset += 2;
      while (depth && offset < sql.length) {
        if (sql.startsWith("/*", offset)) { depth++; offset += 2; }
        else if (sql.startsWith("*/", offset)) { depth--; offset += 2; }
        else offset++;
      }
      if (depth) throw protocolError("Unterminated SQL comment");
    } else break;
  }
  return /^[a-z]+/i.exec(sql.slice(offset))?.[0].toUpperCase();
}

function bounded(promise, milliseconds, timeout) {
  let timer;
  const deadline = new Promise((_, reject) => {
    timer = setTimeout(() => {
      const error = protocolError("Hyperdrive operation deadline exceeded", "TIMEOUT");
      reject(error);
      try { timeout(error); } catch { /* Preserve the deadline failure. */ }
    }, milliseconds);
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timer));
}

export class HyperdriveHostBridge {
  constructor({ clientFactory, protocolFactory = () => postgresProtocol, ...limits } = {}) {
    if (clientFactory !== undefined && typeof clientFactory !== "function") throw new TypeError("Invalid Hyperdrive client factory");
    this.clientFactory = clientFactory;
    this.protocolFactory = protocolFactory;
    this.limits = { ...HYPERDRIVE_DEFAULT_LIMITS, ...limits };
    for (const [key, value] of Object.entries(this.limits)) {
      if (!(key in HYPERDRIVE_DEFAULT_LIMITS) || !Number.isSafeInteger(value) || value < 1 || value > 2147483647) {
        throw new TypeError(`Invalid Hyperdrive limit: ${key}`);
      }
    }
    this.capabilities = new Map();
    this.registered = new WeakSet();
  }

  register(perl) {
    if (this.registered.has(perl)) return;
    perl.registerFunction(HYPERDRIVE_HOST_FUNCTION_NAME, async value => perl.createString(await this.call(value.toString())));
    this.registered.add(perl);
  }

  attachScope(scope, bindings, names, { request, asyncCleanup = false } = {}) {
    names = hyperdriveBindingNames(names);
    if (!names.length) return { release() {} };
    if (!asyncCleanup) throw new Error("Hyperdrive requires a runtime with awaited extension cleanup");
    if (!this.clientFactory) throw new Error("Use the Hyperdrive entry point or supply hyperdriveClientFactory");
    if (!scope?.extensions || typeof scope.extensions !== "object" || Array.isArray(scope.extensions)
      || scope.extensions[HYPERDRIVE_EXTENSION_NAME]) throw new Error("Invalid or already attached Hyperdrive scope");
    const allowed = new Map();
    for (const name of names) {
      if (typeof bindings?.[name]?.connectionString !== "string" || !bindings[name].connectionString) throw new Error(`Missing Hyperdrive binding ${name}`);
      allowed.set(name, { connectionString: bindings[name].connectionString,
        protocol: this.protocolFactory(bindings[name].connectionString) });
    }
    const capability = crypto.randomUUID();
    const state = { allowed, connections: new Map(), released: false };
    this.capabilities.set(capability, state);
    const extension = { version: 1, capability, bindings: names };
    scope.extensions[HYPERDRIVE_EXTENSION_NAME] = extension;
    const revoke = () => {
      state.released = true;
      this.capabilities.delete(capability);
      if (scope.extensions[HYPERDRIVE_EXTENSION_NAME] === extension) delete scope.extensions[HYPERDRIVE_EXTENSION_NAME];
    };
    const abort = () => { revoke(); };
    request?.signal.addEventListener("abort", abort, { once: true });
    if (request?.signal.aborted) revoke();
    let cleanup;
    return {
      release: ({ signal } = {}) => {
        if (cleanup) return cleanup;
        revoke();
        const force = error => {
          for (const connection of state.connections.values()) this.destroy(connection, error);
        };
        const aborted = () => force(protocolError("Runtime cleanup cancelled", "CLEANUP_ABORTED"));
        signal?.addEventListener("abort", aborted, { once: true });
        if (signal?.aborted) aborted();
        cleanup = bounded(Promise.allSettled([...state.connections.values()].map(async connection => {
          await connection.pending;
          await this.close(connection);
        })).then(results => {
          const errors = results.filter(result => result.status === "rejected").map(result => result.reason);
          if (errors.length) throw new AggregateError(errors, "Hyperdrive cleanup failed");
        }), this.limits.cleanupTimeoutMs, force).finally(() => {
          signal?.removeEventListener("abort", aborted);
          request?.signal.removeEventListener("abort", abort);
          state.connections.clear();
        });
        return cleanup;
      },
    };
  }

  destroy(connection, error) {
    connection.broken = true;
    try { connection.client?.destroy(error); } catch { /* All other clients must still be destroyed. */ }
  }

  async close(connection) {
    if (!connection.client || connection.closed) return;
    connection.closed = true;
    let primary;
    try {
      if (!connection.broken && connection.transaction) {
        await this.query(connection, "ROLLBACK", []);
        connection.transaction = false;
      }
    } catch (error) { primary = error; this.destroy(connection, error); }
    try {
      await bounded(connection.client.close(), this.limits.cleanupTimeoutMs, error => this.destroy(connection, error));
    }
    catch (error) {
      this.destroy(connection, error);
      if (primary) throw new AggregateError([primary, error], "Rollback and disconnect failed");
      throw error;
    }
    if (primary) throw primary;
  }

  async query(connection, text, values) {
    return bounded(connection.client.query({ text, values, limits: this.limits }), this.limits.queryTimeoutMs,
      error => this.destroy(connection, error));
  }

  async call(input) {
    let protocol = postgresProtocol;
    try {
      if (typeof input !== "string" || new TextEncoder().encode(input).length > this.limits.maxRequestBytes) throw protocolError("Request limit exceeded", "REQUEST_LIMIT");
      let wire;
      try { wire = JSON.parse(input); } catch { throw protocolError("Invalid request JSON"); }
      if (!wire || Array.isArray(wire) || wire.version !== 1) throw protocolError("Invalid protocol version");
      const state = this.capabilities.get(wire.capability);
      if (!state || state.released) throw protocolError("Expired request capability", "CAPABILITY_EXPIRED");
      if (!state.allowed.has(wire.binding)) throw protocolError("Binding not allowed", "BINDING_DENIED");
      protocol = state.allowed.get(wire.binding).protocol;
      const operations = ["open", "query", "begin", "commit", "rollback", "disconnect"];
      if (!operations.includes(wire.operation)) throw protocolError("Invalid operation");
      const keys = ["version", "capability", "binding", "operation", "connection", "owner"];
      if (wire.operation === "query") keys.push("sql", "params");
      if (wire.operation === "begin") keys.push("managed");
      if (Object.keys(wire).some(key => !keys.includes(key))) throw protocolError("Unknown request field");
      if (wire.operation === "open") {
        if (wire.connection !== undefined || wire.owner !== undefined) throw protocolError("Invalid open request");
        if (state.connections.size >= this.limits.maxConnections) throw protocolError("Connection limit exceeded", "CONNECTION_LIMIT");
        const id = crypto.randomUUID();
        state.connections.set(id, { binding: wire.binding, pending: Promise.resolve(), transaction: false, failed: false });
        return JSON.stringify({ version: 1, ok: true, result: { connection: id } });
      }
      const connection = state.connections.get(wire.connection);
      if (!connection || connection.binding !== wire.binding) throw protocolError("Unknown connection", "CONNECTION_CLOSED");
      let values;
      if (wire.operation === "query") {
        if (typeof wire.sql !== "string" || !wire.sql.trim() || wire.sql.includes("\0") || !Array.isArray(wire.params)) throw protocolError("Invalid query");
        const keyword = protocol.validateQuery ? "DRIVER_VALIDATED" : firstKeyword(wire.sql);
        if (!keyword) throw protocolError("Query must start with a SQL keyword after comments");
        if (["BEGIN", "START", "COMMIT", "END", "ROLLBACK", "ABORT", "SAVEPOINT", "RELEASE", "PREPARE", "EXECUTE", "DEALLOCATE", "DISCARD", "SET", "RESET"].includes(keyword)) {
          throw protocolError("Use transaction operations; session control SQL is unsupported", "TRANSACTION_CONTROL");
        }
        values = wire.params.map(protocol.decodeParameter);
      }
      if (wire.operation === "begin" && typeof wire.managed !== "boolean") throw protocolError("begin requires a managed boolean");
      if (wire.owner !== undefined && (typeof wire.owner !== "string" || !wire.owner)) throw protocolError("Invalid transaction owner");
      const pending = connection.pending.then(async () => {
        if (state.released) throw protocolError("Expired request capability", "CAPABILITY_EXPIRED");
        if (connection.closed) throw protocolError("Connection closed", "CONNECTION_CLOSED");
        if (wire.owner !== connection.owner) throw protocolError("Transaction ownership mismatch", "TRANSACTION_OWNER");
        if (wire.operation === "disconnect") {
          await this.close(connection);
          connection.closed = true;
          state.connections.delete(wire.connection);
          return {};
        }
        if (connection.broken) throw protocolError("Connection is unusable", "CONNECTION_BROKEN");
        if (wire.operation === "begin" && connection.transaction) throw protocolError("Nested transactions are unsupported", "TRANSACTION_ACTIVE");
        if (["commit", "rollback"].includes(wire.operation) && !connection.transaction) throw protocolError("No active transaction", "NO_TRANSACTION");
        if (connection.failed && wire.operation !== "rollback") throw protocolError("Transaction requires rollback", "TRANSACTION_FAILED");
        if (wire.operation === "query") protocol.validateQuery?.(wire.sql, values, connection.transaction);
        let received = false;
        try {
          if (!connection.client) {
            connection.client = this.clientFactory({ connectionString: state.allowed.get(wire.binding).connectionString, limits: this.limits,
              onError: error => { this.destroy(connection, error); } });
            await bounded(connection.client.connect(), this.limits.connectTimeoutMs, error => this.destroy(connection, error));
            connection.connected = true;
          }
          const sql = wire.operation === "query" ? wire.sql : wire.operation.toUpperCase();
          const result = await this.query(connection, sql, values ?? []);
          received = true;
          if (wire.operation === "begin") {
            connection.transaction = true;
            connection.owner = wire.managed ? crypto.randomUUID() : undefined;
          } else if (["commit", "rollback"].includes(wire.operation)) {
            connection.transaction = false;
            connection.failed = false;
            connection.owner = undefined;
          }
          const encoded = protocol.encodeResult(result, this.limits);
          return { ...encoded, connection: wire.connection, ...(connection.owner ? { owner: connection.owner } : {}) };
        } catch (error) {
          if (!error || typeof error !== "object") error = new Error("Driver failed");
          if (connection.transaction) connection.failed = true;
          if (!connection.connected || !protocol.databaseError(error) || /^(08|57P0)/.test(error.code ?? "")
            || ["FATAL", "PANIC"].includes(error.severity)) this.destroy(connection, error);
          if (wire.operation === "commit" && !received && (connection.broken || /^(08|57P0)/.test(error.code ?? ""))) error.outcomeUnknown = true;
          throw error;
        }
      });
      connection.pending = pending.catch(() => undefined);
      return JSON.stringify({ version: 1, ok: true, result: await pending });
    } catch (error) {
      return JSON.stringify({ version: 1, ok: false, error: protocol.publicError(error) });
    }
  }
}
