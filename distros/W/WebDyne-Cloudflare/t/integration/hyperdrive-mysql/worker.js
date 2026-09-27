import generated from './.webdyne/worker.js';
import {authenticated} from './auth.js';
import {createConnection} from 'mysql2/promise';
export default {async fetch(request,env,ctx) {
  if(!authenticated(request,env))return new Response('Unauthorized',{status:401});
  const token=new URL(request.url).searchParams.get('token');
  if(!/^[a-f0-9-]{36}$/.test(token??''))return new Response('Invalid token',{status:400});
  const table='webdyne_mysql_'+token.replaceAll('-','');
  const db=await createConnection({host:env.DB.host,port:env.DB.port,user:env.DB.user,password:env.DB.password,database:env.DB.database,disableEval:true});
  let created=false;
  try {
    await db.query(`CREATE TABLE ${table} (id BIGINT PRIMARY KEY AUTO_INCREMENT, slot INT UNIQUE, value TEXT, document JSON, moment DATETIME(6)) ENGINE=InnoDB AUTO_INCREMENT=9007199254740993`);created=true;
    const pending=[];
    const response=await generated.fetch(request,env,{waitUntil(promise){pending.push(promise);ctx.waitUntil(promise);}});
    const body=await response.text();
    let completion='fulfilled';try{await Promise.all(pending);}catch{completion='rejected';}
    const [rows]=await db.query(`SELECT slot,value FROM ${table} ORDER BY slot`);
    const verified=new URL(request.url).pathname==='/' ? rows.length===1&&rows[0].slot===1&&rows[0].value==='committed' : rows.length===0;
    return Response.json({status:response.status,body,completion,verified,rows});
  } finally {if(created)await db.query(`DROP TABLE ${table}`);await db.end();}
}};
