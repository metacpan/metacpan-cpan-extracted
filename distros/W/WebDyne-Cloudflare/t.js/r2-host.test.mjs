import assert from "node:assert/strict";
import test from "node:test";
import {
  R2HostBridge,
  R2_EXTENSION_NAME,
  R2_HOST_FUNCTION_NAME,
  r2BindingNames,
} from "../js/r2-host.js";

function r2Fixture() {
  const calls = [];
  const metadata = (key = "webdyne/example.bin") => ({
    key,
    version: "version-one",
    size: 3,
    etag: "etag-one",
    httpEtag: '"etag-one"',
    uploaded: new Date("2026-09-03T00:00:00.000Z"),
    httpMetadata: { contentType: "application/octet-stream" },
    customMetadata: { source: "WebDyne" },
    storageClass: "Standard",
  });
  const body = {
    ...metadata(),
    body: {},
    async arrayBuffer() { return Uint8Array.from([0, 1, 255]).buffer; },
  };
  const bucket = {
    async get(key, options) { calls.push(["get", key, options]); return key === "missing" ? null : body; },
    async head(key) { calls.push(["head", key]); return key === "missing" ? null : metadata(key); },
    async put(key, value, options) { calls.push(["put", key, value, options]); return metadata(key); },
    async delete(keys) { calls.push(["delete", keys]); },
    async list(options) {
      calls.push(["list", options]);
      return { objects: [metadata()], truncated: false, delimitedPrefixes: [] };
    },
  };
  return { bucket, calls };
}

function request(overrides = {}) {
  return {
    version: 1,
    capability: "r2-capability",
    binding: "ASSETS",
    operation: "get",
    key: "webdyne/example.bin",
    ...overrides,
  };
}

test("normalizes R2 binding allow-lists", () => {
  assert.deepEqual(r2BindingNames(["ASSETS", "ARCHIVE", "ASSETS"]), ["ASSETS", "ARCHIVE"]);
  assert.throws(() => r2BindingNames("bad-name"), /Invalid R2 binding name/);
});

test("attaches, dispatches, and releases an R2 capability", async () => {
  const { bucket } = r2Fixture();
  const bridge = new R2HostBridge({ tokenFactory: () => "r2-capability" });
  const scope = { extensions: {} };
  const attachment = bridge.attachScope(scope, { ASSETS: bucket }, ["ASSETS"]);
  assert.deepEqual(scope.extensions[R2_EXTENSION_NAME], {
    version: 1,
    capability: "r2-capability",
    bindings: ["ASSETS"],
  });
  assert.equal((await bridge.dispatch(request())).body.base64, "AAH/");
  attachment.release();
  assert.equal(scope.extensions[R2_EXTENSION_NAME], undefined);
  await assert.rejects(bridge.dispatch(request()), /invalid or has expired/);
});

test("supports R2 get, head, put, list, range, and delete", async () => {
  const { bucket, calls } = r2Fixture();
  const bridge = new R2HostBridge({ tokenFactory: () => "r2-capability" });
  bridge.attachScope({ extensions: {} }, { ASSETS: bucket }, ["ASSETS"]);

  const object = await bridge.dispatch(request({ range: { offset: 1, length: 2 } }));
  assert.equal(object.http_etag, '"etag-one"');
  assert.equal(object.uploaded, "2026-09-03T00:00:00.000Z");
  assert.deepEqual(calls[0][2], { range: { offset: 1, length: 2 } });
  assert.equal((await bridge.dispatch(request({ operation: "head" }))).body, undefined);
  await bridge.dispatch(request({
    operation: "put",
    value: { type: "bytes", base64: "AAH/" },
    http_metadata: { content_type: "application/octet-stream" },
    custom_metadata: { source: "WebDyne" },
  }));
  assert.deepEqual([...calls.at(-1)[2]], [0, 1, 255]);
  assert.deepEqual(calls.at(-1)[3], {
    httpMetadata: { contentType: "application/octet-stream" },
    customMetadata: { source: "WebDyne" },
  });
  assert.equal(await bridge.dispatch(request({ operation: "delete", keys: ["one", "two"] })), true);
  const listed = await bridge.dispatch(request({
    operation: "list", prefix: "webdyne/", include: ["customMetadata"], limit: 10,
  }));
  assert.equal(listed.objects[0].key, "webdyne/example.bin");
});

test("registers one structured R2 host function per interpreter", async () => {
  const callbacks = new Map();
  const perl = {
    registerFunction(name, callback) { callbacks.set(name, callback); },
    createString(value) { return { value, toString() { return value; } }; },
  };
  const bridge = new R2HostBridge({ tokenFactory: () => "r2-capability" });
  bridge.register(perl);
  bridge.register(perl);
  assert.equal(callbacks.size, 1);
  const response = JSON.parse((await callbacks.get(R2_HOST_FUNCTION_NAME)({
    toString: () => JSON.stringify(request()),
  })).toString());
  assert.equal(response.ok, false);
  assert.match(response.error.message, /invalid or has expired/);
});

test("rejects unavailable R2 bindings and objects over the bridge limit", async () => {
  const bridge = new R2HostBridge({ tokenFactory: () => "r2-capability", maxObjectBytes: 2 });
  assert.throws(
    () => bridge.attachScope({ extensions: {} }, { ASSETS: {} }, ["ASSETS"]),
    /binding ASSETS is unavailable/,
  );
  const { bucket } = r2Fixture();
  bridge.attachScope({ extensions: {} }, { ASSETS: bucket }, ["ASSETS"]);
  await assert.rejects(bridge.dispatch(request()), /byte limit/);
  await assert.rejects(
    bridge.dispatch(request({ operation: "put", value: "three" })),
    /byte limit/,
  );
});
