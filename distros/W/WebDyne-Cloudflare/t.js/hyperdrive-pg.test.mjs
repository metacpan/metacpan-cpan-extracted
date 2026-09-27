import test from "node:test";
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { createPgClient } from "../js/hyperdrive-pg.js";

function setup() {
  let native;
  class Client extends EventEmitter {
    constructor(config) {
      super(); native = this; this.config = config; this.destroyed = 0;
      this.connection = { stream: { destroy: () => { this.destroyed++; } } };
    }
    async connect() {}
    async end() {}
    query(query) { this.active = query; }
  }
  const errors = [];
  const adapter = createPgClient({ connectionString: "private", limits: { connectTimeoutMs: 12 }, onError: error => errors.push(error) }, { Client });
  return { adapter, native, errors };
}

test("adapter uses pg extended protocol and row events without pg accumulation", async () => {
  const { adapter, native } = setup();
  const pending = adapter.query({ text: "select $1", values: ["9007199254740993"], limits: { maxRows: 10, maxResultBytes: 1000 } });
  const query = native.active;
  assert.equal(query.queryMode, "extended"); assert.equal(query._rowMode, "array");
  assert.equal(query.callback, undefined);
  query.handleRowDescription({ fields: [{ name: "x", dataTypeID: 20, format: "text" }] });
  assert.equal(query._accumulateRows, false);
  query.handleDataRow({ fields: ["9007199254740993"] });
  query.handleCommandComplete({ text: "SELECT 1" });
  query.handleReadyForQuery({});
  const result = await pending;
  assert.deepEqual(result.rows, [["9007199254740993"]]);
  assert.equal(result.rowCount, 1); assert.equal(result.command, "SELECT");
  assert.deepEqual(query._result.rows, []);
});

test("adapter aborts on row or encoded byte limit while receiving rows", async () => {
  for (const limits of [{ maxRows: 1, maxResultBytes: 1000 }, { maxRows: 10, maxResultBytes: 5 }]) {
    const { adapter, native } = setup();
    const pending = adapter.query({ text: "select x", values: [], limits });
    const query = native.active;
    query.handleRowDescription({ fields: [{ name: "x", dataTypeID: 25, format: "text" }] });
    query.handleDataRow({ fields: ["one"] }); query.handleDataRow({ fields: ["two"] });
    await assert.rejects(pending, { code: "RESULT_LIMIT" });
    assert.equal(native.destroyed, 1);
    query.handleDataRow({ fields: ["ignored"] });
    query.emit("error", new Error("late socket failure"));
    assert.deepEqual(query._result.rows, []);
  }
});

test("database and idle socket errors are observed; forced close is idempotent", async () => {
  const { adapter, native, errors } = setup();
  const pending = adapter.query({ text: "bad sql", values: [], limits: { maxRows: 10, maxResultBytes: 1000 } });
  native.active.handleError(Object.assign(new Error("syntax error"), { code: "42601" }), {});
  await assert.rejects(pending, { code: "42601" });
  const error = new Error("connection lost"); native.emit("error", error);
  assert.deepEqual(errors, [error]); adapter.destroy(error); adapter.destroy(error);
  assert.equal(native.destroyed, 1);
});

test("Workers rejected socket.closed settles forced cleanup even without pg end", async () => {
  let native;
  class Client extends EventEmitter {
    constructor() {
      super(); native = this;
      let rejectClosed;
      const closed = new Promise((_, reject) => { rejectClosed = reject; });
      this.connection = { stream: { _cfSocket: { closed }, destroy() { rejectClosed(new Error("socket aborted")); } } };
    }
    end() { return new Promise(() => {}); }
  }
  const adapter = createPgClient({ connectionString: "private", limits: { connectTimeoutMs: 5 }, onError() {} }, { Client });
  adapter.destroy(new Error("query deadline"));
  await adapter.close();
  assert.ok(native);
});
