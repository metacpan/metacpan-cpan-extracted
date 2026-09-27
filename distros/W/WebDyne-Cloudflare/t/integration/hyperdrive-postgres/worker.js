import generated from './.webdyne/worker.js';
import {authenticated} from './auth.js';
import pg from 'pg';
async function database(env,callback) {
  // Independent verification must outlive the deliberately sleeping origin query.
  const client=new pg.Client({connectionString:env.DB.connectionString,connectionTimeoutMillis:15000,query_timeout:15000});
  client.on('error',()=>{});
  try {await client.connect();return await callback(client);} finally {await client.end();}
}
async function execute(request,env,ctx) {
  const pending=[];
  const response=await generated.fetch(request,env,{waitUntil(promise){pending.push(promise);ctx.waitUntil(promise);}});
  const body=await response.text(); let completion='fulfilled';
  try {await Promise.all(pending);} catch {completion='rejected';}
  return {status:response.status,body,completion};
}
export default {
  async fetch(request,env,ctx) {
    if(!authenticated(request,env)) return new Response('Unauthorized',{status:401});
    const url=new URL(request.url);const token=url.searchParams.get('token');
    if(!/^[a-f0-9-]{36}$/.test(token??'')) return new Response('Invalid token',{status:400});
    if(url.pathname==='/cleanup'&&request.method==='POST') return database(env,async client=>Response.json({deleted:(await client.query('DELETE FROM webdyne_hyperdrive_test.transaction_probe WHERE run_token=$1',[token])).rowCount}));
    if(request.method!=='GET')return new Response('Not found',{status:404});
    if(url.pathname==='/verify')return database(env,async client=>Response.json((await client.query('SELECT slot,value FROM webdyne_hyperdrive_test.transaction_probe WHERE run_token=$1 ORDER BY slot',[token])).rows));
    if(url.pathname==='/activity') {
      const pid=url.searchParams.get('pid');if(!/^\d+$/.test(pid??''))return new Response('Invalid pid',{status:400});
      return database(env,async client=>Response.json((await client.query('SELECT state,wait_event AS wait FROM pg_stat_activity WHERE pid=$1::integer',[pid])).rows));
    }
    if(url.pathname==='/sequence') {
      const results=[];
      for(const path of ['/prime','/stale','/failure','/health']) {
        const next=new URL(url);next.pathname=path;
        results.push({path,...await execute(new Request(next,request),env,ctx)});
      }
      return Response.json(results);
    }
    if(url.pathname==='/abort')return generated.fetch(request,env,{waitUntil(promise){ctx.waitUntil(promise.then(()=> 'fulfilled',()=> 'rejected').then(status=>database(env,client=>client.query(
      'INSERT INTO webdyne_hyperdrive_test.transaction_probe VALUES ($1,9000,$2)',[token,JSON.stringify({status,aborted:request.signal.aborted})]))));}});
    if(!['/run','/sql','/limits','/network','/health'].includes(url.pathname))return new Response('Not found',{status:404});
    return Response.json(await execute(request,env,ctx));
  }
};
