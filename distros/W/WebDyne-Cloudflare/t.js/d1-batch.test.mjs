import assert from 'node:assert/strict';
import test from 'node:test';
import { D1HostBridge, D1_HOST_FUNCTION_NAME } from '../js/d1-host.js';

function fixture() {
  const calls = [];
  const database = {
    prepare(sql) {
      calls.push(['prepare', sql]);
      return { sql, params: [], bind(...params) { return {sql, params}; } };
    },
    async batch(statements) {
      calls.push(['batch', statements]);
      return statements.map((statement, index) => ({
        success: true, meta: {changes: index},
        results: [{sql: statement.sql, payload: [0, 255], type: 'blob', base64: 'AA=='}],
      }));
    },
  };
  const bridge = new D1HostBridge({tokenFactory: () => 'batch-capability'});
  const attachment = bridge.attachScope({}, {DB: database}, ['DB']);
  const request = {
    version: 1, capability: attachment.capability, binding: 'DB', operation: 'batch',
    statements: [
      {sql: 'SELECT ?1, ?2, ?3, ?4, ?5', params: [0, '', null, 'π', {type: 'blob', base64: 'AP8='}]},
      {sql: 'SELECT 2'},
    ],
  };
  return {bridge, attachment, request, database, calls};
}

test('batch binds all statements and executes one ordered provider batch', async () => {
  const {bridge, request, calls} = fixture();
  const result = await bridge.dispatch(request);
  assert.equal(calls.filter(([operation]) => operation === 'batch').length, 1);
  const statements = calls.at(-1)[1];
  assert.deepEqual(statements[0].params.slice(0, 4), [0, '', null, 'π']);
  assert.deepEqual([...statements[0].params[4]], [0, 255]);
  assert.deepEqual(statements.map(({sql}) => sql), request.statements.map(({sql}) => sql));
  assert.deepEqual(result.map(({meta}) => meta.changes), [0, 1]);
  assert.deepEqual(result[1].results[0], {
    sql: 'SELECT 2', payload: {type: 'blob', base64: 'AP8='}, type: 'blob', base64: 'AA==',
  });
});

test('malformed batches fail before preparing any provider statements', async () => {
  const {bridge, request, calls} = fixture();
  for (const statements of [undefined, [], {}, [null], [{sql: ''}],
    [request.statements[0], {sql: 'SELECT ?1', params: {}}],
    [request.statements[0], {sql: 'SELECT ?1', params: [{}]}]]) {
    await assert.rejects(bridge.dispatch({...request, statements}));
  }
  assert.deepEqual(calls, []);
});

test('batch uses only its permitted binding and expires with the request', async () => {
  const {bridge, request, attachment, calls} = fixture();
  await assert.rejects(bridge.dispatch({...request, binding: 'OTHER'}), /not allowed/);
  await assert.rejects(bridge.dispatch({...request, capability: 'other-request'}), /expired/);
  attachment.release();
  await assert.rejects(bridge.dispatch(request), /expired/);
  assert.deepEqual(calls, []);
});

test('provider batch failure is structured and the next batch can succeed', async () => {
  const {bridge, request, database} = fixture();
  const batch = database.batch;
  database.batch = async () => { throw Object.assign(new Error('constraint failed'), {code: 7500}); };
  let callback;
  bridge.register({
    registerFunction(name, value) { assert.equal(name, D1_HOST_FUNCTION_NAME); callback = value; },
    createString(value) { return value; },
  });
  const failed = JSON.parse(await callback({toString: () => JSON.stringify(request)}));
  assert.equal(failed.ok, false);
  assert.equal(failed.error.code, 7500);
  assert.match(failed.error.message, /constraint failed/);
  database.batch = batch;
  const recovered = JSON.parse(await callback({toString: () => JSON.stringify(request)}));
  assert.equal(recovered.ok, true);
  assert.equal(recovered.result.length, 2);
});
