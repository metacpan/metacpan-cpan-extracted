import assert from "node:assert/strict";
import test from "node:test";
import { createWebDyneCloudflareExtension } from "../js/cloudflare.js";
import { D1_EXTENSION_NAME, D1_HOST_FUNCTION_NAME } from "../js/d1-host.js";
import { KV_EXTENSION_NAME, KV_HOST_FUNCTION_NAME } from "../js/kv-host.js";
import { R2_EXTENSION_NAME, R2_HOST_FUNCTION_NAME } from "../js/r2-host.js";

const d1 = { prepare() {}, batch() {} };
const kv = {
  get() {}, getWithMetadata() {}, put() {}, delete() {}, list() {},
};
const r2 = {
  get() {}, head() {}, put() {}, delete() {}, list() {},
};

test("the npm lifecycle keeps D1, KV, and R2 capabilities independent", () => {
  const extension = createWebDyneCloudflareExtension({
    d1Bindings: ["DB"],
    kvBindings: ["CACHE"],
    r2Bindings: ["ASSETS"],
  });
  const callbacks = new Map();
  extension.register({
    registerFunction(name, callback) { callbacks.set(name, callback); },
  });
  assert.deepEqual([...callbacks.keys()].sort(), [
    "WebDyne::Cloudflare::SecretsStore::Host::call",
    "WebDyne::Cloudflare::DurableObject::Host::call",
    D1_HOST_FUNCTION_NAME,
    KV_HOST_FUNCTION_NAME,
    R2_HOST_FUNCTION_NAME,
  ].sort());

  const scope = { extensions: {} };
  const attachment = extension.attachScope({
    scope,
    bindings: { DB: d1, CACHE: kv, ASSETS: r2, SECRET: kv },
  });
  assert.deepEqual(scope.extensions[D1_EXTENSION_NAME].bindings, ["DB"]);
  assert.deepEqual(scope.extensions[KV_EXTENSION_NAME].bindings, ["CACHE"]);
  assert.deepEqual(scope.extensions[R2_EXTENSION_NAME].bindings, ["ASSETS"]);
  assert.equal(JSON.stringify(scope).includes("SECRET"), false);
  attachment.release();
  attachment.release();
  assert.deepEqual(scope.extensions, {});
});

test("the npm lifecycle falls back to explicit compatibility variables", () => {
  const extension = createWebDyneCloudflareExtension();
  const scope = { extensions: {} };
  extension.attachScope({
    scope,
    bindings: {
      DB: d1,
      CACHE: kv,
      ASSETS: r2,
      WEBDYNE_D1_BINDINGS: "DB",
      WEBDYNE_KV_BINDINGS: "CACHE",
      WEBDYNE_R2_BINDINGS: "ASSETS",
    },
  });
  assert.deepEqual(Object.keys(scope.extensions).sort(), [
    D1_EXTENSION_NAME,
    KV_EXTENSION_NAME,
    R2_EXTENSION_NAME,
  ].sort());
});
