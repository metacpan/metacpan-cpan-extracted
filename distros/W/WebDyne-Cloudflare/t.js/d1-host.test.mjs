import assert from "node:assert/strict";
import test from "node:test";
import { D1HostBridge, D1_EXTENSION_NAME, D1_HOST_FUNCTION_NAME, d1BindingNames } from "../js/d1-host.js";
import { createWebDyneCloudflareExtension } from "../js/cloudflare.js";

function fixture(name = "WebDyne") {
  const calls = [];
  const statement = {
    bind(...params) { calls.push(["bind", params]); return this; },
    async run() {
      calls.push(["run"]);
      return { success: true, meta: { changes: 1 }, results: [{ id: 7, payload: [0, 1, 255] }] };
    },
    async first(column) {
      calls.push(["first", column]);
      return column === "payload" ? [0, 1, 255] : { id: 7, name };
    },
    async raw(options) { calls.push(["raw", options]); return [[7, [0, 1, 255]]]; },
  };
  const database = {
    prepare(sql) { calls.push(["prepare", sql]); return statement; },
    batch() {},
  };
  return { calls, database };
}

function request(overrides = {}) {
  return {
    version: 1,
    capability: "capability-token",
    binding: "DB",
    operation: "run",
    sql: "SELECT ?1",
    params: [42],
    ...overrides,
  };
}

test("normalizes an explicit binding allow-list", () => {
  assert.deepEqual(d1BindingNames(" DB,ANALYTICS,DB "), ["DB", "ANALYTICS"]);
  assert.deepEqual(d1BindingNames("DB,"), ["DB"]);
  assert.throws(() => d1BindingNames("bad-name"), /Invalid D1 binding name/);
});

test("attaches and releases an opaque request capability", async () => {
  const { database } = fixture();
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  const scope = { extensions: {} };
  const attachment = bridge.attachScope(scope, { DB: database }, ["DB"]);
  assert.deepEqual(scope.extensions[D1_EXTENSION_NAME], {
    version: 1,
    capability: "capability-token",
    bindings: ["DB"],
    session_bindings: [],
  });
  assert.equal((await bridge.dispatch(request())).success, true);
  attachment.release();
  await assert.rejects(bridge.dispatch(request()), /invalid or has expired/);
});

test("uses prepared parameters and preserves blob values", async () => {
  const { calls, database } = fixture();
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  bridge.attachScope({ extensions: {} }, { DB: database }, ["DB"]);
  const result = await bridge.dispatch(request({
    params: [{ type: "blob", base64: "AAH/" }],
  }));
  assert.deepEqual([...calls[1][1][0]], [0, 1, 255]);
  assert.deepEqual(result.results[0].payload, { type: "blob", base64: "AAH/" });
});

test("supports first column and raw result modes", async () => {
  const { database } = fixture();
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  bridge.attachScope({ extensions: {} }, { DB: database }, ["DB"]);
  assert.deepEqual(await bridge.dispatch(request({ operation: "first", column: "payload" })), {
    type: "blob", base64: "AAH/",
  });
  assert.deepEqual(await bridge.dispatch(request({ operation: "raw", column_names: true })), [
    [7, { type: "blob", base64: "AAH/" }],
  ]);
});

test("registers one structured-error host function per interpreter", async () => {
  const callbacks = new Map();
  const perl = {
    registerFunction(name, callback) { callbacks.set(name, callback); },
    createString(value) { return { value, toString() { return value; } }; },
  };
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  bridge.register(perl);
  bridge.register(perl);
  assert.equal(callbacks.size, 1);
  const response = JSON.parse((await callbacks.get(D1_HOST_FUNCTION_NAME)({
    toString: () => JSON.stringify(request()),
  })).toString());
  assert.equal(response.ok, false);
  assert.match(response.error.message, /invalid or has expired/);
});

test("does not expose configured non-D1 values", () => {
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  assert.throws(
    () => bridge.attachScope({ extensions: {} }, { DB: "secret" }, ["DB"]),
    /binding DB is unavailable/,
  );
});

test("isolates concurrent request capabilities", async () => {
  const tokens = ["capability-one", "capability-two"];
  const bridge = new D1HostBridge({ tokenFactory: () => tokens.shift() });
  bridge.attachScope({ extensions: {} }, { DB: fixture("first").database }, ["DB"]);
  bridge.attachScope({ extensions: {} }, { DB: fixture("second").database }, ["DB"]);
  const [first, second] = await Promise.all([
    bridge.dispatch(request({ capability: "capability-one", operation: "first" })),
    bridge.dispatch(request({ capability: "capability-two", operation: "first" })),
  ]);
  assert.equal(first.name, "first");
  assert.equal(second.name, "second");
});

test("rejects a malformed PAGI extension container", () => {
  const bridge = new D1HostBridge({ tokenFactory: () => "capability-token" });
  assert.throws(
    () => bridge.attachScope({ extensions: [] }, { DB: fixture().database }, ["DB"]),
    /scope extensions must be an object/,
  );
});

test("exposes the npm extension lifecycle with a fixed D1 allow-list", () => {
  const extension = createWebDyneCloudflareExtension({ d1Bindings: ["DB"] });
  const callbacks = new Map();
  extension.register({
    registerFunction(name, callback) { callbacks.set(name, callback); },
  });
  assert.equal(callbacks.has(D1_HOST_FUNCTION_NAME), true);

  const scope = { extensions: {} };
  const { database } = fixture();
  const attachment = extension.attachScope({
    scope,
    bindings: { DB: database, SECRET: fixture().database },
  });
  assert.deepEqual(scope.extensions[D1_EXTENSION_NAME].bindings, ["DB"]);
  attachment.release();
});
