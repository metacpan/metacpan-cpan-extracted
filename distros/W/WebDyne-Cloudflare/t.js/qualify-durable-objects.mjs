// Run against a packaged ZeroPerl runtime; no hosted resources are created.
import assert from 'node:assert/strict';
import { execFileSync, spawn } from 'node:child_process';
import { mkdtemp, mkdir, cp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { once } from 'node:events';
const root=resolve(fileURLToPath(new URL('..',import.meta.url)));
const runtime=process.argv[2];
if(!runtime)throw new Error('Usage: node t.js/qualify-durable-objects.mjs RUNTIME_VERSION');
const directory=await mkdtemp(join(tmpdir(),'webdyne-do-qualification-'));
const cache=join(directory,'cache');
const execute=(cmd,args)=>execFileSync(cmd,args,{cwd:directory,encoding:'utf8',env:{...process.env,npm_config_cache:cache,XDG_CONFIG_HOME:join(directory,'config'),WRANGLER_SEND_METRICS:'false'},maxBuffer:16*1024*1024});
let server;
async function stop(){if(server&&server.exitCode===null){const done=once(server,'exit');server.kill('SIGTERM');await done;}server=undefined;}
let base;
let log='';
async function start(){
  log='';
  server=spawn(process.execPath,[join(root,'node_modules/wrangler/bin/wrangler.js'),'dev','--config','wrangler.jsonc','--port','0','--inspector-port','0'],{cwd:directory,env:{...process.env,XDG_CONFIG_HOME:join(directory,'config'),WRANGLER_SEND_METRICS:'false'},stdio:['ignore','pipe','pipe']});
  for(const stream of [server.stdout,server.stderr])stream.on('data',chunk=>{log+=chunk;});
  for(let attempt=0;attempt<300;attempt++){
    const match=log.match(/Ready on (http:\/\/[^\s\x1b]+)/);
    if(match){base=match[1];return;}
    if(server.exitCode!==null)throw new Error(log);
    await new Promise(resolve=>setTimeout(resolve,100));
  }
  throw new Error(`Server startup timeout: ${log}`);
}
async function call(name,method,args=[]){const response=await fetch(`${base}/call`,{method:'POST',body:JSON.stringify({name,method,args}),signal:AbortSignal.timeout(30000)});assert.equal(response.status,200,await response.clone().text());return response.json();}
try{
  await mkdir(join(directory,'app'));
  await cp(join(root,'t/fixtures/durable-object/app.pagi'),join(directory,'app/app.pagi'));
  await mkdir(join(directory,'lib/Example'),{recursive:true});
  await cp(join(root,'t/fixtures/durable-object/Probe.pm'),join(directory,'lib/Example/Probe.pm'));
  await cp(join(root,'t/fixtures/durable-object/worker.js'),join(directory,'worker.js'));
  const [packed]=JSON.parse(execFileSync('npm',['pack','--json','--ignore-scripts','--pack-destination',directory,'--cache',cache],{cwd:root,encoding:'utf8'}));
  const pkg=JSON.parse(await readFile(join(root,'examples/durable-objects/package.json')));
  pkg.dependencies={'@webdyne/webdyne-zeroperl-5.44.0':/^\d+\.\d+\.\d+(?:-[\w.-]+)?$/.test(runtime) ? runtime : resolve(runtime),'@webdyne/webdyne-cloudflare':join(directory,packed.filename)};
  pkg.webdyne.entry='app.pagi';
  const definition=pkg.webdyne.cloudflare.durableObjects[0];
  definition.perlPackage='Example::Probe';definition.methods=['increment','read','echo','rollback','remember','stale','cycle','delay','failure'];
  await writeFile(join(directory,'package.json'),JSON.stringify(pkg));
  execute('npm',['install','--ignore-scripts']);
  execute('npm',['run','check']);
  const config=JSON.parse(await readFile(join(directory,'.webdyne/wrangler.jsonc')));
  config.main='worker.js';
  await writeFile(join(directory,'wrangler.jsonc'),JSON.stringify(config));
  const entry=join(directory,'.webdyne/worker.js');
  let source=await readFile(entry,'utf8');
  source=source.replaceAll('createRuntime: createWebDyneRuntime','createRuntime: measuredRuntime');
  source+=`\nconst measuredPerls=[];\nfunction measuredRuntime(options){return createWebDyneRuntime({...options,extensions:[...options.extensions,{register(perl){measuredPerls.push(perl);}}]});}\nexport function runtimeMemory(){return measuredPerls.map(perl=>perl.exports.memory.buffer.byteLength);}\n`;
  await writeFile(entry,source);
  execute(process.execPath,[join(root,'node_modules/wrangler/bin/wrangler.js'),'deploy','--dry-run','--config','wrangler.jsonc']);
  await start();
  const began=performance.now();
  assert.equal((await call('one','read')).result.value,0);
  const coldMs=performance.now()-began;
  const writes=await Promise.all(Array.from({length:12},()=>call('one','delay')));
  assert.ok(writes.every(value=>value.ok),JSON.stringify(writes));
  assert.equal((await call('one','read')).result.value,12);
  assert.equal((await call('two','read')).result.value,0);
  assert.equal((await call('one','read')).result.starts,1);
  assert.equal((await call('one','rollback')).ok,false);
  assert.equal((await call('one','read')).result.value,12);
  assert.equal((await call('one','remember')).ok,true);
  assert.match((await call('one','stale')).error.message,/expired/);
  assert.match((await call('one','cycle',[['one']])).error.message,/cycle|re-entry/);
  assert.match((await call('one','cycle',[['two','one']])).error.message,/cycle|re-entry/);
  const error=await call('one','failure');assert.equal(error.ok,false);assert.match(error.error.message,/expected failure/);
  const nested={type:'bytes',base64:'ordinary',t:'hash',v:['雪',null,true,0]};
  assert.deepEqual((await call('one','echo',[nested])).result,nested);
  const client=await fetch(base,{method:'POST',signal:AbortSignal.timeout(30000)});
  assert.deepEqual(await client.json(),{value:1});
  const memory=await (await fetch(`${base}/memory`)).json();
  console.log(JSON.stringify({phase:'warm',coldMs,wasmBytes:memory,tests:'concurrency, isolation, atomic rollback, stale capability, call cycles, errors, serialization, Perl client RPC'}));
  await stop();assert.doesNotMatch(log,/Failed to drain the unused request body/);await start();
  const restored=await call('one','read');assert.equal(restored.result.value,12);assert.equal(restored.result.starts,1);
  console.log(JSON.stringify({phase:'restart',restored:restored.result,tests:'SQLite persistence and repeatable initialization after Worker restart'}));
} catch(error){console.error(log);throw error;}
finally{await stop();await rm(directory,{recursive:true,force:true});}
