// Explicit opt-in: creates and removes its own table in a disposable database.
import assert from 'node:assert/strict';
import mysql from 'mysql2/promise';
import {createMysqlClient,mysqlProtocol} from '../js/hyperdrive-mysql.js';
import {HYPERDRIVE_DEFAULT_LIMITS as limits} from '../js/hyperdrive-host.js';
const connectionString=process.env.WEBDYNE_MYSQL_TEST_URL;
if(!connectionString)throw new Error('Set WEBDYNE_MYSQL_TEST_URL to a disposable MySQL/MariaDB database');
const verifier=await mysql.createConnection(connectionString);
const table='webdyne_test_'+crypto.randomUUID().replaceAll('-','');
let created=false;
const make=async()=>{const c=createMysqlClient({connectionString,limits,onError(){}});await c.connect();return c;};
let client=await make();
const query=async(text,values=[])=>mysqlProtocol.encodeResult(await client.query({text,values,limits}),limits);
try {
  const [version]=await verifier.query('SELECT VERSION() AS version');
  await query(`CREATE TABLE ${table} (id BIGINT PRIMARY KEY AUTO_INCREMENT, value TEXT, amount DECIMAL(30,10), payload BLOB, document JSON, moment DATETIME(6)) ENGINE=InnoDB AUTO_INCREMENT=9007199254740993`);created=true;
  assert.equal(String((await query('SELECT 42 LIMIT ? OFFSET ?',['1','0'])).rows[0][0][1]),'42');
  const input="O'Brien \\ '; DROP TABLE t; -- 日本🍷";
  const result=await query(`INSERT INTO ${table} (value,amount,payload,document,moment) VALUES (?,?,?,?,?)`,[input,'12345678901234567890.1234567890',Buffer.from([0,255]),'null','2024-02-29 23:59:59.999999']);
  assert.equal(result.insert_id,'9007199254740993');assert.equal(result.affected_rows,1);
  const row=(await query(`SELECT id,value,amount,payload,document,moment FROM ${table}`)).rows[0];
  assert.deepEqual(row,[['text','9007199254740993'],['text',input],['text','12345678901234567890.1234567890'],['bytes','00ff'],['text','null'],['text','2024-02-29 23:59:59.999999']]);
  await query('BEGIN');await query(`UPDATE ${table} SET value=?`,['rolled back']);await query('ROLLBACK');
  assert.equal((await query(`SELECT value FROM ${table}`)).rows[0][0][1],input);
  await query('BEGIN');await query(`UPDATE ${table} SET value=?`,['committed']);await query('COMMIT');
  assert.equal((await verifier.query(`SELECT value FROM ${table}`))[0][0].value,'committed');
  await assert.rejects(query(`INSERT INTO ${table} (id) VALUES (?)`,['9007199254740993']),e=>mysqlProtocol.publicError(e).sqlstate==='23000');
  // Binding remains safe with both normal and NO_BACKSLASH_ESCAPES SQL modes.
  await client.close();
  const mode=await mysql.createConnection(connectionString);
  const [previous]=await mode.query('SELECT @@GLOBAL.sql_mode AS mode');
  try {
    await mode.query("SET GLOBAL sql_mode='NO_BACKSLASH_ESCAPES,ANSI_QUOTES'");
    client=await make();assert.equal((await query('SELECT ? AS value',[input])).rows[0][0][1],input);
  } finally {await mode.query('SET GLOBAL sql_mode=?',[previous[0].mode]);await mode.end();}
  console.log(JSON.stringify({ok:true,version:version[0].version,checks:['types','insert_id','parameters','SQL modes','commit','rollback','duplicate error']}));
} finally {await client.close();if(created)await verifier.query(`DROP TABLE ${table}`);await verifier.end();}
