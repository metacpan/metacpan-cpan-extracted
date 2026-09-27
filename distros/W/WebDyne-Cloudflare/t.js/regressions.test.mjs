import assert from "node:assert/strict";
import test from "node:test";
import { D1HostBridge } from "../js/d1-host.js";
import { KVHostBridge } from "../js/kv-host.js";
import { R2HostBridge } from "../js/r2-host.js";

for (const Bridge of [D1HostBridge, KVHostBridge, R2HostBridge]) {
  test(`${Bridge.name} retries failed registration`, () => {
    const bridge = new Bridge();
    let calls = 0;
    const perl = { registerFunction() { if (++calls === 1) throw new Error("registration failed"); } };
    assert.throws(() => bridge.register(perl), /registration failed/);
    bridge.register(perl);
    bridge.register(perl);
    assert.equal(calls, 2);
  });
}

test("KV enforces its configured read limit for all result modes", async () => {
  const namespace = {
    async get(_key, { type }) {
      return type === "arrayBuffer" ? new Uint8Array(5).buffer : type === "json" ? {long: "value"} : "πππ";
    },
    async getWithMetadata(key, options) { return {value: await this.get(key, options), metadata: null}; },
    put() {}, delete() {}, list() {},
  };
  const bridge = new KVHostBridge({maxValueBytes: 4});
  const attachment = bridge.attachScope({}, {CACHE: namespace}, ["CACHE"]);
  try {
    for (const operation of ["get", "get_with_metadata"]) {
      for (const type of ["text", "json", "bytes"]) {
        await assert.rejects(bridge.dispatch({
          version: 1, capability: attachment.capability, binding: "CACHE", key: "key", operation, type,
        }), /configured byte limit/);
      }
    }
  } finally { attachment.release(); }
});

test("R2 cancels a rejected oversized body without buffering it", async () => {
  let cancelled = false;
  const bucket = {
    async get() { return {
      size: 5, body: {async cancel() { cancelled = true; }},
      arrayBuffer() { throw new Error("must not buffer"); },
    }; },
    head() {}, put() {}, delete() {}, list() {},
  };
  const bridge = new R2HostBridge({maxObjectBytes: 4});
  const attachment = bridge.attachScope({}, {OBJECTS: bucket}, ["OBJECTS"]);
  try {
    await assert.rejects(bridge.dispatch({
      version: 1, capability: attachment.capability, binding: "OBJECTS", key: "key", operation: "get",
    }), /configured byte limit/);
    assert.equal(cancelled, true);
  } finally { attachment.release(); }
});
