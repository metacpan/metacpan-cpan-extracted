import test from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { mysqlSql, mysqlProtocol, createMysqlClient } from '../js/hyperdrive-mysql.js';
import { hyperdriveProtocol } from '../js/hyperdrive.js';
import { HyperdriveHostBridge, HYPERDRIVE_DEFAULT_LIMITS as limits } from '../js/hyperdrive-host.js';

const field = (name, type, charset = 45) => ({ name, columnType:type, flags:0, characterSet:charset });
test('binding schemes select the driver without exposing configuration to Perl', () => {
  assert.equal(hyperdriveProtocol('mysql://user:secret@host/db').name, 'mysql');
  assert.equal(hyperdriveProtocol('postgresql://user:secret@host/db').name, 'postgres');
  assert.throws(() => hyperdriveProtocol('https://host'), /Unsupported/);
});
test('MySQL placeholders ignore literals and comments and encode values independently of SQL modes', () => {
  const sql = mysqlSql("SELECT ?, '?', `?`, \"?\", ? /* ? */ # ?\n -- ?\n", ["'\\'; DROP TABLE t; -- 🐪", Buffer.from([0,255])]);
  assert.ok(sql.sql.includes("CONVERT(X'275c273b2044524f50205441424c4520743b202d2d20f09f90aa' USING utf8mb4)"));
  assert.ok(sql.sql.includes("X'00ff'"));
  assert.ok(sql.sql.includes("'?'"));
  assert.equal(mysqlSql('SELECT ?, ?', [null, false]).sql, 'SELECT NULL, 0');
  assert.equal(mysqlSql('SELECT 1 LIMIT ? OFFSET ?', ['10','0']).sql, 'SELECT 1 LIMIT 10 OFFSET 0');
  assert.equal(mysqlSql('SELECT 1 LIMIT ?, ?', ['0','10']).sql, 'SELECT 1 LIMIT 0, 10');
  assert.equal(mysqlSql('SELECT 1 LIMIT 0, ?', ['10']).sql, 'SELECT 1 LIMIT 0, 10');
  assert.throws(()=>mysqlSql('SELECT 1 LIMIT ?', ['1; DROP TABLE t']),{code:'PARAMETER_TYPE'});
  assert.equal(mysqlSql('SELECT ?', ['001']).sql, "SELECT CONVERT(X'303031' USING utf8mb4)");
  for (const input of ['SELECT ??', 'SELECT 1; DROP TABLE t', 'SELECT 1 /*!; COMMIT */', '/*M! COMMIT */ SELECT 1', "SELECT 'a\\b'", 'SET autocommit=1', 'CALL procedure_name()', 'USE db', 'LOCK TABLES t WRITE', 'XA START x', 'LOAD DATA LOCAL INFILE x']) {
    assert.throws(() => mysqlSql(input, []));
  }
  assert.throws(() => mysqlSql('SELECT ?', []), {code:'PARAMETER_COUNT'});
  assert.throws(() => mysqlSql('SELECT 1', ['extra']), {code:'PARAMETER_COUNT'});
  assert.throws(() => mysqlSql('DROP TABLE t', [], {transaction:true}), {code:'TRANSACTION_CONTROL'});
  assert.equal(mysqlSql('#comment\nSELECT 1; -- comment', []).command, 'SELECT');
});
test('MySQL values and metadata preserve exact text, bytes, duplicate columns and insert IDs', () => {
  const result = mysqlProtocol.encodeResult({fields:[field('x',8),field('x',3),field('d',246),field('json',245),field('blob',252,63),field('nil',6)],rows:[['9007199254740993',3,'12.3400','null',Buffer.from([0,255]),null]],rowCount:1,command:'SELECT'},limits);
  assert.deepEqual(result.rows, [[['text','9007199254740993'],['number',3],['text','12.3400'],['text','null'],['bytes','00ff'],['null']]]);
  assert.deepEqual(result.columns.map(c=>c.name),['x','x','d','json','blob','nil']);
  const write=mysqlProtocol.encodeResult({fields:[],rows:[],rowCount:0,command:'UPDATE',affectedRows:0,insertId:'9007199254740993',warningStatus:1},limits);
  assert.equal(write.insert_id,'9007199254740993'); assert.equal(write.affected_rows,0); assert.equal(write.warning_count,1);
});
test('MySQL errors expose SQLSTATE and errno while redacting connection failures', () => {
  const error=Object.assign(new Error('query with secret'), {code:'ER_DUP_ENTRY',errno:1062,sqlState:'23000',sqlMessage:'Duplicate entry'});
  assert.equal(mysqlProtocol.publicError(error).sqlstate,'23000');
  assert.equal(mysqlProtocol.publicError(error).message,'Duplicate entry');
  for(const error of [new Error('mysql://user:secret@host'),{code:'ER_ACCESS_DENIED_ERROR',errno:1045,sqlState:'28000',fatal:true,sqlMessage:'secret'}]) {
    assert.equal(mysqlProtocol.publicError(error).code,'CONNECTION_ERROR'); assert.ok(!JSON.stringify(mysqlProtocol.publicError(error)).includes('secret'));
  }
});
function mockDriver() {
  const connection=new EventEmitter(); let options;
  connection.stream=new EventEmitter();connection.stream.destroy=()=>connection.stream.emit('close');
  connection.connect=cb=>cb(); connection.end=cb=>{cb();connection.stream.emit('close');}; connection.destroy=()=>{ connection.destroyed=true; };
  connection.query=()=>{const q=new EventEmitter(); connection.current=q; return q;};
  const client=createMysqlClient({connectionString:'mysql://u:p@host:123/db',limits,onError(){}},{createConnection:config=>{options=config;return connection;}});
  return {client,connection,get options(){return options;}};
}
test('static streaming driver bounds rows, closes on overflow and preserves primary failure',async()=>{
  const f=mockDriver(); await f.client.connect();
  assert.equal(f.options.disableEval,true); assert.equal(f.options.bigNumberStrings,true); assert.equal(f.options.jsonStrings,true); assert.equal(f.options.multipleStatements,false);
  const pending=f.client.query({text:'SELECT 1',values:[],limits:{...limits,maxRows:1}});
  f.connection.current.emit('fields',[field('x',3)]); f.connection.current.emit('result',[1]); f.connection.current.emit('result',[2]);
  await assert.rejects(pending,{code:'RESULT_LIMIT'}); assert.equal(f.connection.destroyed,true); await f.client.close();
});
test('streamed DML metadata, SQL errors and transport errors settle the query',async()=>{
  const f=mockDriver(); await f.client.connect();
  let pending=f.client.query({text:'INSERT INTO t VALUES (?)',values:['x'],limits});
  f.connection.current.emit('fields',undefined);
  f.connection.current.emit('result',{affectedRows:1,insertId:'9007199254740993',warningStatus:0});f.connection.current.emit('end');
  assert.equal((await pending).insertId,'9007199254740993');
  pending=f.client.query({text:'SELECT 1',values:[],limits});f.connection.current.emit('error',Object.assign(new Error('bad SQL'),{code:'ER_PARSE_ERROR'}));
  await assert.rejects(pending,{code:'ER_PARSE_ERROR'});await f.client.close();
});
test('MySQL bridge enforces transaction state, rollback, commit ambiguity and binding isolation',async()=>{
  let fail;const queries=[];
  const bridge=new HyperdriveHostBridge({protocolFactory:hyperdriveProtocol,clientFactory:()=>({async connect(){},async close(){},destroy(){},async query({text}){queries.push(text);if(fail)throw fail;return {fields:[],rows:[],rowCount:0,command:text};}})});
  const scope={extensions:{}};const attachment=bridge.attachScope(scope,{DB:{connectionString:'mysql://u:p@host/db'}},['DB'],{asyncCleanup:true});
  const capability=scope.extensions['webdyne.cloudflare.hyperdrive'].capability;
  const call=async(operation,extra={})=>JSON.parse(await bridge.call(JSON.stringify({version:1,capability,binding:'DB',operation,...extra})));
  const connection=(await call('open')).result.connection;
  await call('begin',{connection,managed:false});
  assert.equal((await call('query',{connection,sql:'CREATE TABLE t(id INT)',params:[]})).error.code,'TRANSACTION_CONTROL');
  assert.equal(queries.length,1);
  fail={code:'ER_DUP_ENTRY',errno:1062,sqlState:'23000',sqlMessage:'Duplicate entry'};
  assert.equal((await call('query',{connection,sql:'INSERT INTO t VALUES (?)',params:[['text','1']]})).error.code,'ER_DUP_ENTRY');
  assert.equal((await call('commit',{connection})).error.code,'TRANSACTION_FAILED');
  fail=null;assert.equal((await call('rollback',{connection})).ok,true);
  await call('begin',{connection,managed:false}); fail=new Error('private password');
  const result=await call('commit',{connection});assert.equal(result.error.outcomeUnknown,true);assert.equal(result.error.code,'CONNECTION_ERROR');
  await attachment.release();
});

test('forced MySQL cleanup waits for actual socket closure',async()=>{
 const f=mockDriver();await f.client.connect();let force=0;
 f.connection.stream.destroy=()=>{force++;};
 f.client.destroy();f.client.destroy();assert.equal(force,1);
 let settled=false;const pending=f.client.close().then(()=>{settled=true;});
 await Promise.resolve();assert.equal(settled,false);
 f.connection.stream.emit('close');await pending;assert.equal(settled,true);
});

test('mixed PostgreSQL and MySQL bindings keep independent parameter codecs',async()=>{
 const observed=[];const bridge=new HyperdriveHostBridge({protocolFactory:hyperdriveProtocol,clientFactory:config=>({async connect(){},async close(){},destroy(){},async query({values}){observed.push({url:config.connectionString,values});return {fields:[],rows:[],rowCount:0,command:'SELECT'};}})});
 const scope={extensions:{}};const attachment=bridge.attachScope(scope,{PG:{connectionString:'postgres://u:p@host/db'},MY:{connectionString:'mysql://u:p@host/db'}},['PG','MY'],{asyncCleanup:true});
 const capability=scope.extensions['webdyne.cloudflare.hyperdrive'].capability;
 const call=async(binding,operation,fields={})=>JSON.parse(await bridge.call(JSON.stringify({version:1,capability,binding,operation,...fields})));
 for(const binding of ['PG','MY']) {
   const connection=(await call(binding,'open')).result.connection;
   assert.equal((await call(binding,'query',{connection,sql:binding==='PG'?'SELECT $1':'SELECT ?',params:[['bytes','00ff']]})).ok,true);
 }
 assert.equal(observed[0].values[0],'\\x00ff');assert.deepEqual(observed[1].values[0],Buffer.from([0,255]));
 assert.equal(JSON.stringify(scope).includes('postgres://'),false);await attachment.release();
});
