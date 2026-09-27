import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { encodeValue, decodeValue, wire } from '../js/durable-object-codec.js';
import { DurableObjectHostBridge, DURABLE_OBJECT_EXTENSION } from '../js/durable-object-host.js';
import { createDurableObjectClass } from '../js/durable-object-runtime.js';

const id = 'a'.repeat(64);
const other = 'b'.repeat(64);
function storage() {
  const db = new DatabaseSync(':memory:');
  return {
    sql: { exec(sql, ...params) {
      const statement = db.prepare(sql);
      const rows = statement.all(...params.map(p => p instanceof ArrayBuffer ? new Uint8Array(p) : p));
      return Object.assign(rows, { rowsRead: rows.length, rowsWritten: db.prepare('SELECT changes() n').get().n });
    } },
    transactionSync(callback) {
      db.exec('BEGIN');
      try { const value = callback(); db.exec('COMMIT'); return value; }
      catch (error) { db.exec('ROLLBACK'); throw error; }
    },
  };
}
function context(bridge, object, namespaces = {}) {
  const scope = {};
  const attachment = bridge.attachScope(scope, namespaces, Object.keys(namespaces), { durableObject: object });
  return { attachment, request: fields => bridge.dispatch({ version: 1, capability: scope.extensions[DURABLE_OBJECT_EXTENSION].capability, ...fields }) };
}
const statement = (sql, params = []) => ({ sql, params: encodeValue(params) });

test('tagged values preserve arbitrary hashes, Unicode, bytes and null; reject unsafe values', () => {
  const value = { t: 'bytes', v: 'ordinary data', text: '雪', bytes: new Uint8Array([0,255]).buffer, nil: null };
  assert.deepEqual(decodeValue(encodeValue(value)), value);
  for (const value of [undefined, Infinity, NaN, Number.MAX_SAFE_INTEGER+1, 1n, new Date()]) assert.throws(() => encodeValue(value));
  const cycle = {}; cycle.self = cycle; assert.throws(() => encodeValue(cycle), /cyclic/);
  assert.throws(() => decodeValue({t:'bytes',v:'!'}));
  assert.throws(() => wire('x'.repeat(1048576)), /exceeds/);
});

test('SQLite batches roll back all statements and capabilities expire', async () => {
  const bridge = new DurableObjectHostBridge();
  const { request, attachment } = context(bridge, { id, chain:[id], storage:storage() });
  await request({ operation:'sql', statement:statement('CREATE TABLE t(id INTEGER PRIMARY KEY, v TEXT)') });
  await assert.rejects(request({ operation:'batch', statements:[statement('INSERT INTO t VALUES (?,?)',[1,'first']), statement('INSERT INTO missing VALUES (1)')] }), /missing/);
  assert.deepEqual(decodeValue(await request({ operation:'sql', statement:statement('SELECT * FROM t') })).rows, []);
  const result = decodeValue(await request({ operation:'batch', statements:[statement('INSERT INTO t VALUES (?,?)',[1,'雪']),statement('SELECT * FROM t')] }));
  assert.deepEqual(result[1].rows,[{id:1,v:'雪'}]);
  attachment.release();
  await assert.rejects(request({operation:'sql',statement:statement('SELECT 1')}),/expired/);
});

test('client bridge restricts bindings and rejects cycles before invoking a stub', async () => {
  let calls = 0;
  const namespace = {idFromName:()=>({toString:()=>id}),idFromString:value=>({toString:()=>value}),get:()=>({webdyneInvoke:async envelope=>{calls++;return {ok:true,result:envelope.args};}})};
  const {request} = context(new DurableObjectHostBridge(), {id,chain:[id],storage:storage()}, {ROOMS:namespace});
  await assert.rejects(request({binding:'ROOMS',operation:'call',id,method:'read',args:encodeValue([])}),/cycle/);
  assert.equal(calls,0);
  await assert.rejects(request({binding:'SECRET',operation:'resolve',name:'x'}),/not allowed/);
  assert.deepEqual(decodeValue(await request({binding:'ROOMS',operation:'call',id:other,method:'read',args:encodeValue([7])})),[7]);
  assert.equal(calls,1);
});

test('object wrapper serializes full invocations, initializes once and isolates runtimes', async () => {
  let runtimes=0; const events=[];
  let release; const pending = new Promise(resolve=>{release=resolve;});
  class Base {constructor(ctx,env){this.ctx=ctx;this.env=env;}}
  const Class=createDurableObjectClass({DurableObject:Base,definition:{perlPackage:'Test::Room',methods:['read'],initialize:true},
    createRuntime:()=>{const n=++runtimes;return {invoke:async({scope})=>{
      events.push([n,scope.method]);
      if(scope.method==='read'&&decodeValue(scope.args)[0]==='wait')await pending;
      return {ok:true,result:encodeValue(n)};
    }};}});
  const object=new Class({id:{toString:()=>id},storage:storage()},{});
  const first=object.read('wait'); const second=object.read();
  await new Promise(resolve=>setImmediate(resolve));
  assert.deepEqual(events,[[1,'initialize'],[1,'read']]);
  release(); assert.deepEqual(await Promise.all([first,second]),[1,1]);
  assert.deepEqual(events,[[1,'initialize'],[1,'read'],[1,'read']]);
  assert.equal(await new Class({id:{toString:()=>other},storage:storage()},{}).read(),2);
  const cycle=await object.webdyneInvoke({version:1,method:'read',args:encodeValue([]),chain:[id]});
  assert.equal(cycle.ok,false);
  assert.equal((await object.webdyneInvoke({version:1,method:'hidden',args:encodeValue([]),chain:[]})).ok,false);
});

test('failed runtimes are disposed and reinitialized, while reported application errors retain the runtime', async()=>{
  let created=0, disposed=0, starts=0;
  class Base {constructor(ctx,env){this.ctx=ctx;this.env=env;}}
  const Class=createDurableObjectClass({DurableObject:Base,definition:{perlPackage:'App',methods:['read'],initialize:true},createRuntime:()=>{
    const generation=++created;
    return {dispose:async()=>{disposed++;},invoke:async({scope})=>{
      if(scope.method==='initialize'){starts++;return {ok:true,result:null};}
      if(generation===1)throw new Error('cleanup failed');
      return {ok:false,error:{name:'APP_ERROR',message:'ordinary failure'}};
    }};
  }});
  const instance=new Class({id:{toString:()=>id},storage:storage()},{});
  await assert.rejects(instance.read(),/cleanup failed/);
  assert.equal(disposed,1);
  await assert.rejects(instance.read(),/ordinary failure/);
  await assert.rejects(instance.read(),/ordinary failure/);
  assert.equal(created,2);assert.equal(starts,2);
});

test('SQL result limits roll back writes and byte parameters/results survive',async()=>{
  const {request}=context(new DurableObjectHostBridge(),{id,chain:[id],storage:storage()});
  await request({operation:'sql',statement:statement('CREATE TABLE t(v BLOB)')});
  const bytes=new Uint8Array([0,255]).buffer;
  const result=decodeValue(await request({operation:'sql',statement:statement('INSERT INTO t VALUES (?) RETURNING v',[bytes])}));
  assert.deepEqual(result.rows[0].v,bytes);
  await assert.rejects(request({operation:'batch',statements:[statement('DELETE FROM t'),statement("SELECT printf('%.*c', 1048576, 'a') AS large")]}),/exceeds/);
  assert.equal(decodeValue(await request({operation:'sql',statement:statement('SELECT * FROM t')})).rows.length,1);
});

test('native bindings decode arguments, encode results and never retry failures',async()=>{
  let calls=0;
  const namespace={idFromName:()=>({toString:()=>id}),idFromString:value=>({toString:()=>value}),get:()=>({echo:async value=>{calls++;return value;},fail:async()=>{calls++;throw new Error('ambiguous write');}})};
  const {request}=context(new DurableObjectHostBridge({nativeBindings:['NATIVE']}),null,{NATIVE:namespace});
  const args=encodeValue([{binary:new Uint8Array([1,2]).buffer}]);
  assert.deepEqual(decodeValue(await request({operation:'call',binding:'NATIVE',id,method:'echo',args})),decodeValue(args)[0]);
  await assert.rejects(request({operation:'call',binding:'NATIVE',id,method:'fail',args:encodeValue([])}),/ambiguous/);
  assert.equal(calls,2);
});
