import assert from "node:assert/strict";
import test from "node:test";
import { SecretsStoreHostBridge, SECRETS_STORE_EXTENSION_NAME as extensionName,
  SECRETS_STORE_HOST_FUNCTION_NAME as hostName, secretsStoreBindingNames } from "../js/secrets-store-host.js";
import { createWebDyneCloudflareExtension } from "../js/cloudflare.js";
import { createWebDyneHyperdriveExtension } from "../js/hyperdrive.js";

function request(capability, overrides = {}) {
  return { version: 1, capability, binding: "API_KEY", operation: "get", ...overrides };
}
function interpreter() {
  const callbacks = new Map();
  return { callbacks, registerFunction(name, callback) {
    assert.equal(callbacks.has(name), false); callbacks.set(name, callback);
  }, createString(value) { return value; } };
}

test("secret reads preserve strings, stay lazy and do not cache across calls", async () => {
  let value = "dummy π\n\0"; let calls = 0;
  const binding = { async get(...args) { assert.equal(this, binding); assert.deepEqual(args, []); calls++; return value; } };
  const bridge = new SecretsStoreHostBridge({ tokenFactory: () => "secret-token" });
  const scope = {};
  const attachment = bridge.attachScope(scope, { API_KEY: binding, OTHER: binding }, ["API_KEY"]);
  assert.equal(calls, 0);
  assert.deepEqual(scope.extensions[extensionName], { version: 1, capability: "secret-token", bindings: ["API_KEY"] });
  for (value of ["dummy π\n\0", "", "0", "rotated"]) assert.equal(await bridge.dispatch(request("secret-token")), value);
  assert.equal(calls, 4);
  attachment.release(); attachment.release();
  assert.deepEqual(scope.extensions, {});
  await assert.rejects(bridge.dispatch(request("secret-token")), /expired/);
});

test("allowlists and protocol reject unauthorized operations before accessing a secret", async () => {
  assert.deepEqual(secretsStoreBindingNames(" API_KEY,API_KEY "), ["API_KEY"]);
  assert.throws(() => secretsStoreBindingNames("bad-name"), /Invalid/);
  const bridge = new SecretsStoreHostBridge({ tokenFactory: () => "secret-token" });
  let calls = 0;
  assert.throws(() => bridge.attachScope({}, { API_KEY: "plain worker secret" }, ["API_KEY"]), /unavailable/);
  bridge.attachScope({}, { API_KEY: { get() { calls++; return "dummy"; } } }, ["API_KEY"]);
  for (const input of [null, [], request("wrong"), request("secret-token", { binding: "OTHER" }),
    request("secret-token", { version: 2 }), request("secret-token", { operation: "put" }),
    request("secret-token", { secret_name: "OTHER" })]) {
    await assert.rejects(bridge.dispatch(input));
  }
  assert.equal(calls, 0);
});

test("pending reads are revoked without invalidating another request", async () => {
  let resolve; let count = 0;
  const bridge = new SecretsStoreHostBridge({ tokenFactory: () => `token-${++count}-secret` });
  const first = bridge.attachScope({}, { API_KEY: { get: () => new Promise(r => { resolve = r; }) } }, ["API_KEY"]);
  const second = bridge.attachScope({}, { API_KEY: { get: async () => "second" } }, ["API_KEY"]);
  const pending = bridge.dispatch(request("token-1-secret"));
  first.release(); resolve("first");
  await assert.rejects(pending, /expired during retrieval/);
  assert.equal(await bridge.dispatch(request("token-2-secret")), "second");
  second.release();
});

test("registered host redacts provider failures, malformed input and invalid return values", async () => {
  const perl = interpreter(); let result;
  const bridge = new SecretsStoreHostBridge({ tokenFactory: () => "secret-token" });
  bridge.register(perl); bridge.register(perl);
  bridge.attachScope({}, { API_KEY: { get() {
    if (result instanceof Error) throw result;
    return result;
  } } }, ["API_KEY"]);
  const call = perl.callbacks.get(hostName);
  for (result of [Object.assign(new Error("PRIVATE_VALUE"), { cause: "PRIVATE_VALUE", code: "PRIVATE_VALUE" }), null, { value: "PRIVATE_VALUE" }]) {
    const response = await call(JSON.stringify(request("secret-token")));
    assert.equal(JSON.parse(response).ok, false);
    assert.equal(response.includes("PRIVATE_VALUE"), false);
    assert.deepEqual(Object.keys(JSON.parse(response).error).sort(), ["message", "name"]);
  }
  assert.equal((await call("PRIVATE_VALUE")).includes("PRIVATE_VALUE"), false);
  result = "π\n\0";
  assert.equal(JSON.parse(await call(JSON.stringify(request("secret-token")))).result, result);
});

test("extension options, fallback, rollback and Hyperdrive provider preserve isolation", () => {
  const bindings = { API_KEY: { get() {} }, WEBDYNE_SECRETS_STORE_BINDINGS: "API_KEY" };
  for (const factory of [createWebDyneCloudflareExtension, createWebDyneHyperdriveExtension]) {
    for (const options of [{}, { secretsStoreBindings: [] }, { secretsStoreBindings: ["API_KEY"] }]) {
      const extension = factory(options); const scope = {}; const perl = interpreter();
      extension.register(perl);
      assert.ok(perl.callbacks.has(hostName));
      const attached = extension.attachScope({ scope, bindings });
      assert.equal(!!scope.extensions[extensionName], options.secretsStoreBindings?.length !== 0);
      attached.release(); assert.deepEqual(scope.extensions, {});
    }
  }
  const extension = createWebDyneCloudflareExtension({ secretsStoreBindings: ["API_KEY"], d1Bindings: ["MISSING"] });
  const scope = {};
  assert.throws(() => extension.attachScope({ scope, bindings }), /unavailable/);
  assert.deepEqual(scope.extensions, {});
});

test("repeated cleanup cannot revoke a later capability if a token is reused", async () => {
  const bridge = new SecretsStoreHostBridge({ tokenFactory: () => "secret-token" });
  const binding = { get: async () => "dummy" };
  const first = bridge.attachScope({}, { API_KEY: binding }, ["API_KEY"]);
  first.release();
  const second = bridge.attachScope({}, { API_KEY: binding }, ["API_KEY"]);
  first.release();
  assert.equal(await bridge.dispatch(request("secret-token")), "dummy");
  second.release();
});
