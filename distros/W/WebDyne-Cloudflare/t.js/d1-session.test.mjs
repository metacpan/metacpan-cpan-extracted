import assert from 'node:assert/strict';
import test from 'node:test';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { D1HostBridge, D1_EXTENSION_NAME } from '../js/d1-host.js';

const base = {version: 1, capability: 'capability-one', binding: 'DB'};
function fixture() {
  const calls = [];
  const database = {
    prepare() { throw new Error('unexpected primary query'); }, batch() {},
    withSession(constraint) {
      calls.push(constraint);
      let bookmark = null;
      return {
        prepare(sql) {
          const result = {success: true, meta: {served_by_primary: false}, results: [{value: 7}]};
          return {bind() { return this; },
            async run() { if (sql === 'FAIL') throw new Error('query failed'); bookmark = 'bookmark-next'; return result; },
            async first() { bookmark = 'bookmark-first'; return {value: 7}; },
            async raw() { bookmark = 'bookmark-raw'; return [[7]]; }};
        },
        async batch(statements) { return Promise.all(statements.map(s => s.run())); },
        getBookmark() { return bookmark; },
      };
    },
  };
  let count = 0;
  const bridge = new D1HostBridge({tokenFactory: () => ['capability-one', 'capability-two'][count++]});
  const scope = {};
  const attachment = bridge.attachScope(scope, {DB: database, OTHER: database}, ['DB', 'OTHER']);
  bridge.attachScope({}, {DB: database}, ['DB']);
  return {bridge, calls, attachment, scope};
}

test('session modes, reuse, bookmarks and all query shapes', async () => {
  const {bridge, calls, scope} = fixture();
  assert.deepEqual(scope.extensions[D1_EXTENSION_NAME].session_bindings, ['DB', 'OTHER']);
  for (const constraint of [undefined, 'first-primary', 'first-unconstrained', 'bookmark-old']) {
    const session = await bridge.dispatch({...base, operation: 'with_session', constraint});
    const request = {...base, session};
    assert.equal(await bridge.dispatch({...request, operation: 'get_bookmark'}), null);
    const result = await bridge.dispatch({...request, operation: 'run', sql: 'SELECT 7'});
    assert.equal(result.meta.served_by_primary, false);
    assert.equal(await bridge.dispatch({...request, operation: 'get_bookmark'}), 'bookmark-next');
    assert.deepEqual(await bridge.dispatch({...request, operation: 'first', sql: 'SELECT 7'}), {value: 7});
    assert.deepEqual(await bridge.dispatch({...request, operation: 'raw', sql: 'SELECT 7'}), [[7]]);
    assert.equal((await bridge.dispatch({...request, operation: 'batch', statements: [{sql: 'SELECT 7'}]})).length, 1);
    await assert.rejects(bridge.dispatch({...request, operation: 'run', sql: 'FAIL'}), /query failed/);
    assert.equal((await bridge.dispatch({...request, operation: 'run', sql: 'SELECT 7'})).success, true);
  }
  assert.deepEqual(calls, ['first-unconstrained', 'first-primary', 'first-unconstrained', 'bookmark-old']);
});

test('sessions reject cross-request/binding use, malformed input and expiry', async () => {
  const {bridge, attachment} = fixture();
  const session = await bridge.dispatch({...base, operation: 'with_session'});
  const second = await bridge.dispatch({...base, operation: 'with_session'});
  assert.notEqual(session, second);
  await bridge.dispatch({...base, session, operation: 'run', sql: 'SELECT 7'});
  assert.equal(await bridge.dispatch({...base, session: second, operation: 'get_bookmark'}), null);
  for (const override of [{binding: 'OTHER'}, {capability: 'capability-two'}, {session: 'missing'}, {session: null}]) {
    await assert.rejects(bridge.dispatch({...base, session, operation: 'get_bookmark', ...override}), /session is invalid/);
  }
  for (const constraint of [null, '', {}, []]) {
    await assert.rejects(bridge.dispatch({...base, operation: 'with_session', constraint}), /non-empty/);
  }
  await assert.rejects(bridge.dispatch({...base, session, operation: 'with_session'}), /from a session/);
  await assert.rejects(bridge.dispatch({...base, operation: 'get_bookmark'}), /requires a session/);
  attachment.release();
  await assert.rejects(bridge.dispatch({...base, session, operation: 'get_bookmark'}), /expired/);
});

test('real local D1 sessions execute prepared queries and atomic batches through bridge', async () => {
  const mf = new Miniflare(convertV4MiniflareOptions({modules: true, script: 'export default {fetch() {return new Response("ok")}}', d1Databases: ['DB'], compatibilityDate: '2026-09-04'}));
  try {
    const database = await mf.getD1Database('DB');
    await database.exec('CREATE TABLE things (id INTEGER PRIMARY KEY, name TEXT)');
    const bridge = new D1HostBridge({tokenFactory: () => base.capability});
    bridge.attachScope({}, {DB: database}, ['DB']);
    const session = await bridge.dispatch({...base, operation: 'with_session', constraint: 'first-primary'});
    const request = {...base, session};
    await bridge.dispatch({...request, operation: 'run', sql: 'INSERT INTO things VALUES (?, ?)', params: [1, 'hello']});
    assert.deepEqual(await bridge.dispatch({...request, operation: 'first', sql: 'SELECT * FROM things'}), {id: 1, name: 'hello'});
    await assert.rejects(bridge.dispatch({...request, operation: 'batch', statements: [
      {sql: "INSERT INTO things VALUES (2, 'rollback')"}, {sql: "INSERT INTO things VALUES (1, 'duplicate')"},
    ]}));
    assert.equal(await bridge.dispatch({...request, operation: 'first', sql: 'SELECT * FROM things WHERE id=2'}), null);
    const bookmark = await bridge.dispatch({...request, operation: 'get_bookmark'});
    assert.ok(bookmark === null || typeof bookmark === 'string');
  } finally { await mf.dispose(); }
});

test('bindings without native Sessions API remain usable but cannot create sessions', async () => {
  const database = {prepare() { return {async run() { return {success: true, results: []}; }}; }, batch() {}};
  const bridge = new D1HostBridge({tokenFactory: () => base.capability});
  const scope = {};
  bridge.attachScope(scope, {DB: database}, ['DB']);
  assert.deepEqual(scope.extensions[D1_EXTENSION_NAME].session_bindings, []);
  assert.equal((await bridge.dispatch({...base, operation: 'run', sql: 'SELECT 1'})).success, true);
  await assert.rejects(bridge.dispatch({...base, operation: 'with_session'}), /Sessions API is unavailable/);
});
