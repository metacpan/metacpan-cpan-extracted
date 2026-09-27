import assert from "node:assert/strict";
import test from "node:test";
import {
  KVHostBridge,
  KV_EXTENSION_NAME,
  KV_HOST_FUNCTION_NAME,
  kvBindingNames,
} from "../js/kv-host.js";

function fixture() {
  const calls = [];
  const namespace = {
    async get(key, options) {
      calls.push(["get", key, options]);
      if (key === "missing") return null;
      if (options.type === "arrayBuffer") return Uint8Array.from([0, 1, 255]).buffer;
      return options.type === "json" ? { answer: 42 } : "WebDyne";
    },
    async getWithMetadata(key, options) {
      calls.push(["getWithMetadata", key, options]);
      return { value: "WebDyne", metadata: { source: "test" }, cacheStatus: "hit" };
    },
    async put(key, value, options) { calls.push(["put", key, value, options]); },
    async delete(key) { calls.push(["delete", key]); },
    async list(options) {
      calls.push(["list", options]);
      return { keys: [{ name: "webdyne:one", metadata: { source: "test" } }], list_complete: true };
    },
  };
  return { calls, namespace };
}

function request(overrides = {}) {
  return {
    version: 1,
    capability: "kv-capability",
    binding: "CACHE",
    operation: "get",
    key: "example",
    type: "text",
    ...overrides,
  };
}

test("normalizes KV binding allow-lists", () => {
  assert.deepEqual(kvBindingNames(" CACHE,SESSIONS,CACHE "), ["CACHE", "SESSIONS"]);
  assert.throws(() => kvBindingNames("bad-name"), /Invalid KV binding name/);
});

test("attaches, dispatches, and releases a KV capability", async () => {
  const { namespace } = fixture();
  const bridge = new KVHostBridge({ tokenFactory: () => "kv-capability" });
  const scope = { extensions: {} };
  const attachment = bridge.attachScope(scope, { CACHE: namespace }, ["CACHE"]);
  assert.deepEqual(scope.extensions[KV_EXTENSION_NAME], {
    version: 1,
    capability: "kv-capability",
    bindings: ["CACHE"],
  });
  assert.equal(await bridge.dispatch(request()), "WebDyne");
  attachment.release();
  assert.equal(scope.extensions[KV_EXTENSION_NAME], undefined);
  await assert.rejects(bridge.dispatch(request()), /invalid or has expired/);
});

test("supports KV text, bytes, metadata, list, put, and delete", async () => {
  const { calls, namespace } = fixture();
  const bridge = new KVHostBridge({ tokenFactory: () => "kv-capability" });
  bridge.attachScope({ extensions: {} }, { CACHE: namespace }, ["CACHE"]);

  assert.deepEqual(await bridge.dispatch(request({ type: "bytes" })), {
    type: "bytes", base64: "AAH/",
  });
  assert.deepEqual(await bridge.dispatch(request({ type: "json" })), { answer: 42 });
  assert.deepEqual(await bridge.dispatch(request({ operation: "get_with_metadata" })), {
    value: "WebDyne", metadata: { source: "test" }, cache_status: "hit",
  });
  assert.equal(await bridge.dispatch(request({
    operation: "put",
    value: { type: "bytes", base64: "AAH/" },
    expiration_ttl: 60,
    metadata: { source: "test" },
  })), true);
  assert.deepEqual([...calls.at(-1)[2]], [0, 1, 255]);
  assert.deepEqual(calls.at(-1)[3], { expirationTtl: 60, metadata: { source: "test" } });
  assert.equal(await bridge.dispatch(request({ operation: "delete" })), true);
  assert.deepEqual(await bridge.dispatch(request({ operation: "list", prefix: "webdyne:", limit: 10 })), {
    keys: [{ name: "webdyne:one", metadata: { source: "test" } }], list_complete: true,
  });
});

test("registers one structured KV host function per interpreter", async () => {
  const callbacks = new Map();
  const perl = {
    registerFunction(name, callback) { callbacks.set(name, callback); },
    createString(value) { return { value, toString() { return value; } }; },
  };
  const bridge = new KVHostBridge({ tokenFactory: () => "kv-capability" });
  bridge.register(perl);
  bridge.register(perl);
  assert.equal(callbacks.size, 1);
  const response = JSON.parse((await callbacks.get(KV_HOST_FUNCTION_NAME)({
    toString: () => JSON.stringify(request()),
  })).toString());
  assert.equal(response.ok, false);
  assert.match(response.error.message, /invalid or has expired/);
});

test("rejects unavailable KV bindings and unsafe values", async () => {
  const bridge = new KVHostBridge({ tokenFactory: () => "kv-capability", maxValueBytes: 3 });
  assert.throws(
    () => bridge.attachScope({ extensions: {} }, { CACHE: {} }, ["CACHE"]),
    /binding CACHE is unavailable/,
  );
  const { namespace } = fixture();
  bridge.attachScope({ extensions: {} }, { CACHE: namespace }, ["CACHE"]);
  await assert.rejects(bridge.dispatch(request({ operation: "put", value: "four" })), /byte limit/);
  await assert.rejects(bridge.dispatch(request({ operation: "list", limit: 1001 })), /between 1 and 1000/);
  await assert.rejects(bridge.dispatch(request({
    operation: "put", value: "ok", expiration: 1, expiration_ttl: 60,
  })), /expiration or expiration_ttl/);
});
