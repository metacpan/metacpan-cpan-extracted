import test from "node:test";
import assert from "node:assert/strict";
import { HyperdriveHostBridge, HYPERDRIVE_EXTENSION_NAME as EXT } from "../js/hyperdrive-host.js";
import { encodeCell } from "../js/hyperdrive-codec.js";
import { createWebDyneCloudflareExtension } from "../js/cloudflare.js";

const empty = command => ({ fields: [], rows: [], rowCount: null, command });
function fixture(options = {}) {
  const clients = [];
  const bridge = new HyperdriveHostBridge({ clientFactory(config) {
    const client = { config, queries: [], connected: 0, closed: 0, destroyed: 0,
      async connect() { this.connected++; },
      async query({ text, values }) { this.queries.push({ text, values }); return empty(text); },
      async close() { this.closed++; },
      destroy() { this.destroyed++; },
    };
    clients.push(client);
    return client;
  }, ...options });
  const scope = { extensions: {} };
  const controller = new AbortController();
  const attachment = bridge.attachScope(scope, { DB: { connectionString: "secret" } }, ["DB"],
    { asyncCleanup: true, request: new Request("https://example.com", { signal: controller.signal }) });
  const capability = scope.extensions[EXT].capability;
  const call = async (operation, fields = {}) => JSON.parse(await bridge.call(JSON.stringify({ version: 1, capability, binding: "DB", operation, ...fields })));
  const open = async () => (await call("open")).result.connection;
  return { bridge, scope, controller, attachment, clients, call, open };
}

test("lazy logical connections, binding isolation, stale IDs and registration", async () => {
  const f = fixture();
  const connection = await f.open();
  assert.equal(f.clients.length, 0);
  assert.equal((await f.call("query", { connection, sql: "select $1", params: [["text", "O'Reilly"]] })).ok, true);
  assert.equal(f.clients[0].queries[0].values[0], "O'Reilly");
  assert.equal((await f.call("query", { connection, binding: "OTHER", sql: "select 1", params: [] })).error.code, "BINDING_DENIED");
  const other = fixture();
  assert.equal((await other.call("disconnect", { connection })).error.code, "CONNECTION_CLOSED");
  assert.equal((await f.call("disconnect", { connection })).ok, true);
  assert.equal((await f.call("disconnect", { connection })).error.code, "CONNECTION_CLOSED");
  const keys = [];
  const perl = { registerFunction: key => keys.push(key) };
  f.bridge.register(perl); f.bridge.register(perl);
  assert.equal(keys.length, 1);
  await f.attachment.release(); await other.attachment.release();
});

test("managed transactions exclude parent calls, reject nesting and require rollback after SQL failure", async () => {
  const f = fixture(); const connection = await f.open();
  const begun = await f.call("begin", { connection, managed: true });
  const owner = begun.result.owner;
  assert.ok(owner);
  assert.equal((await f.call("query", { connection, sql: "select 1", params: [] })).error.code, "TRANSACTION_OWNER");
  assert.equal((await f.call("begin", { connection, owner, managed: true })).error.code, "TRANSACTION_ACTIVE");
  const client = f.clients[0]; const query = client.query;
  client.query = async () => { throw Object.assign(new Error("duplicate key"), { code: "23505", constraint: "items_pkey" }); };
  const failure = await f.call("query", { connection, owner, sql: "insert into items values ($1)", params: [["text", "1"]] });
  assert.equal(failure.error.code, "23505"); assert.equal(failure.error.constraint, "items_pkey");
  assert.equal((await f.call("commit", { connection, owner })).error.code, "TRANSACTION_FAILED");
  client.query = query;
  assert.equal((await f.call("rollback", { connection, owner })).ok, true);
  assert.equal((await f.call("commit", { connection })).error.code, "NO_TRANSACTION");
  await f.attachment.release();
});

test("separate connections never share transactions; teardown rolls back and closes both", async () => {
  const f = fixture(); const a = await f.open(); const b = await f.open();
  await f.call("begin", { connection: a, managed: false });
  await f.call("query", { connection: b, sql: "select 1", params: [] });
  const cleanup = f.attachment.release();
  assert.equal(f.attachment.release(), cleanup);
  assert.equal(f.scope.extensions[EXT], undefined);
  assert.equal((await f.call("open")).error.code, "CAPABILITY_EXPIRED");
  await cleanup;
  assert.deepEqual(f.clients.map(client => client.queries.map(query => query.text)), [["BEGIN", "ROLLBACK"], ["select 1"]]);
  assert.deepEqual(f.clients.map(client => client.closed), [1, 1]);
});

test("ordered work revalidates state after release; abort revokes before cleanup", async () => {
  const f = fixture(); const connection = await f.open();
  await f.call("begin", { connection, managed: false });
  let finish;
  f.clients[0].query = ({ text }) => text === "ROLLBACK" ? Promise.resolve(empty(text)) : new Promise(resolve => { finish = () => resolve(empty(text)); });
  const active = f.call("query", { connection, sql: "select 1", params: [] });
  await Promise.resolve(); await Promise.resolve();
  const queued = f.call("query", { connection, sql: "select 2", params: [] });
  f.controller.abort();
  assert.equal((await f.call("open")).error.code, "CAPABILITY_EXPIRED");
  const cleanup = f.attachment.release(); finish();
  assert.equal((await active).ok, true);
  assert.equal((await queued).error.code, "CAPABILITY_EXPIRED");
  await cleanup;
});

test("query deadline destroys client; lost commit has unknown outcome and no retry", async () => {
  const f = fixture({ queryTimeoutMs: 15 }); const connection = await f.open();
  await f.call("begin", { connection, managed: false });
  f.clients[0].query = () => new Promise(() => {});
  const result = await f.call("commit", { connection });
  assert.equal(result.error.code, "TIMEOUT"); assert.equal(result.error.outcomeUnknown, true);
  assert.ok(f.clients[0].destroyed);
  assert.equal((await f.call("query", { connection, sql: "select 1", params: [] })).error.code, "CONNECTION_BROKEN");
  await f.attachment.release();
});

test("cleanup deadline closes all clients even when one stalls", async () => {
  const f = fixture({ cleanupTimeoutMs: 15 }); const connection = await f.open();
  await f.call("begin", { connection, managed: false });
  f.clients[0].close = () => new Promise(() => {});
  await assert.rejects(f.attachment.release(), { code: "TIMEOUT" });
  assert.ok(f.clients[0].destroyed);
});

test("protocol validation, connection limits, result limits and credential redaction", async () => {
  const f = fixture({ maxConnections: 1, maxRows: 1 }); const connection = await f.open();
  assert.equal((await f.call("open")).error.code, "CONNECTION_LIMIT");
  for (const sql of ["/* /* nested */ x */ COMMIT", "--comment\nBEGIN", "SET search_path TO public"]) {
    assert.equal((await f.call("query", { connection, sql, params: [] })).error.code, "TRANSACTION_CONTROL");
  }
  assert.equal((await f.call("query", { connection, sql: "select 1", params: [["bytes", "zz"]] })).error.code, "PROTOCOL_ERROR");
  assert.equal(JSON.parse(await f.bridge.call("{")).error.code, "PROTOCOL_ERROR");
  await f.call("query", { connection, sql: "select 1", params: [] });
  f.clients[0].query = async () => ({ fields: [{ name: "x", dataTypeID: 23 }], rows: [["1"], ["2"]], command: "SELECT", rowCount: 2 });
  assert.equal((await f.call("query", { connection, sql: "select 1", params: [] })).error.code, "RESULT_LIMIT");
  await f.attachment.release();
  const g = fixture(); const id = await g.open();
  await g.call("query", { connection: id, sql: "select 1", params: [] });
  g.clients[0].query = async () => { throw new Error("postgres://user:secret@host"); };
  assert.equal(JSON.stringify(await g.call("query", { connection: id, sql: "select 1", params: [] })).includes("secret"), false);
  await g.attachment.release();
});

test("exact values preserve NULL, JSON null, big integers, numerics, timestamps and duplicate columns", async () => {
  const cases = [[null, 25, ["null"]], ["null", 114, ["text", "null"]],
    ["9007199254740993", 20, ["text", "9007199254740993"]], ["123.0000000001", 1700, ["text", "123.0000000001"]],
    ["2026-09-12 01:02:03.123456+09:30", 1184, ["text", "2026-09-12 01:02:03.123456+09:30"]],
    ["\\x00ff80", 17, ["bytes", "00ff80"]], ["f", 16, ["bool", false]], ["Infinity", 701, ["special", "Infinity"]]];
  for (const [value, oid, expected] of cases) assert.deepEqual(encodeCell(value, oid), expected);
  const f = fixture(); const connection = await f.open();
  await f.call("query", { connection, sql: "select 1", params: [] });
  f.clients[0].query = async () => ({ fields: [{ name: "x", dataTypeID: 20 }, { name: "x", dataTypeID: 23 }], rows: [["9007199254740993", "2"]], command: "SELECT", rowCount: 1 });
  const result = (await f.call("query", { connection, sql: "select 1", params: [] })).result;
  assert.deepEqual(result.columns.map(column => column.name), ["x", "x"]);
  assert.deepEqual(result.rows, [[["text", "9007199254740993"], ["number", 2]]]);
  await f.attachment.release();
});

test("legacy runtime fails closed; combined extension preserves awaited cleanup", async () => {
  const f = fixture();
  assert.throws(() => f.bridge.attachScope({ extensions: {} }, { DB: { connectionString: "x" } }, ["DB"]), /awaited extension cleanup/);
  const extension = createWebDyneCloudflareExtension({ hyperdriveBindings: ["DB"], hyperdriveClientFactory: () => { throw new Error("lazy"); } });
  const scope = { extensions: {} };
  const attached = extension.attachScope({ scope, bindings: { DB: { connectionString: "x" } }, lifecycle: { asyncCleanup: true } });
  const cleanup = attached.release();
  assert.ok(cleanup instanceof Promise); assert.equal(attached.release(), cleanup);
  assert.equal(scope.extensions[EXT], undefined); await cleanup;
  await f.attachment.release();
});

test("disconnect is bounded and rollback/close failures remain separate", async () => {
  const f = fixture({ cleanupTimeoutMs: 15 }); const connection = await f.open();
  await f.call("begin", { connection, managed: false });
  f.clients[0].close = () => new Promise(() => {});
  assert.equal((await f.call("disconnect", { connection })).error.code, "TIMEOUT");
  assert.ok(f.clients[0].destroyed); await f.attachment.release();
  const g = fixture(); const second = await g.open();
  await g.call("begin", { connection: second, managed: false });
  const rollback = new Error("rollback failed"); const close = new Error("close failed");
  g.clients[0].query = async () => { throw rollback; };
  g.clients[0].close = async () => { throw close; };
  await assert.rejects(g.attachment.release(), error => {
    assert.deepEqual(error.errors[0].errors, [rollback, close]); return true;
  });
});

test("invalid scope and oversized requests fail without allocating capabilities or clients", async () => {
  const f = fixture({ maxRequestBytes: 256 });
  assert.throws(() => f.bridge.attachScope({ extensions: 1 }, { DB: { connectionString: "x" } }, ["DB"], { asyncCleanup: true }), /Invalid/);
  assert.equal(f.bridge.capabilities.size, 1);
  assert.equal((await f.call("query", { sql: "x".repeat(512), params: [] })).error.code, "REQUEST_LIMIT");
  assert.equal(f.clients.length, 0); await f.attachment.release();
});

test("five-character socket codes are redacted and fatal SQLSTATE closes the client", async () => {
  for (const failure of [Object.assign(new Error("postgres://private:password@host"), { code: "EPIPE" }),
    Object.assign(new Error("terminating connection"), { code: "57P01", severity: "FATAL" })]) {
    const f = fixture(); const connection = await f.open();
    await f.call("begin", { connection, managed: false });
    f.clients[0].query = async () => { throw failure; };
    const response = await f.call("commit", { connection });
    assert.ok(response.error.outcomeUnknown);
    assert.ok(f.clients[0].destroyed);
    if (failure.code === "EPIPE") {
      assert.equal(response.error.code, "CONNECTION_ERROR");
      assert.equal(JSON.stringify(response).includes("password"), false);
    }
    await f.attachment.release();
  }
});
