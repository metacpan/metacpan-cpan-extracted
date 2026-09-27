import {cp,mkdir,writeFile,realpath} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {randomBytes} from 'node:crypto';
const packageSource=async value=>/^\d+\.\d+\.\d+(?:-[\w.-]+)?$/.test(value) ? value : pathToFileURL(await realpath(value)).href;
const [runtime,extension,destination,bindingId]=process.argv.slice(2);
if(!bindingId || !/^[a-f0-9]{32}$/.test(bindingId)) throw new Error('Usage: stage.mjs RUNTIME_VERSION EXTENSION_VERSION NEW_DIRECTORY HYPERDRIVE_ID');
const source=dirname(fileURLToPath(import.meta.url)); const target=resolve(destination);
await mkdir(target); await mkdir(resolve(target,'app'));
await cp(resolve(source,'app.pagi'),resolve(target,'app/app.pagi'));
await cp(resolve(source,'../support/auth.js'),resolve(target,'auth.js'));
await cp(resolve(source,'worker.js'),resolve(target,'worker.js'));
const name=`webdyne-mysql-qual-${randomBytes(4).toString('hex')}`;
await writeFile(resolve(target,'package.json'),JSON.stringify({name,private:true,type:'module',
  scripts:{build:'webdyne-cloudflare build',check:'webdyne-cloudflare check'},
  dependencies:{'@webdyne/webdyne-zeroperl-5.44.0':await packageSource(runtime),
    '@webdyne/webdyne-cloudflare':await packageSource(extension),mysql2:'3.24.4'},
  webdyne:{entry:'app.pagi',static:false,extensions:{'@webdyne/webdyne-cloudflare':{hyperdriveBindings:['DB'],hyperdriveLimits:{maxConnections:2,maxRows:10,maxResultBytes:8192,queryTimeoutMs:5000,cleanupTimeoutMs:5000}}},
    cloudflare:{name,compatibilityDate:'2026-09-13',hyperdrive:[{binding:'DB',id:bindingId}]}}},null,2));
await writeFile(resolve(target,'.deployment-secrets.json'),JSON.stringify({PROTOTYPE_TOKEN:randomBytes(32).toString('hex'),PROTOTYPE_EXPIRES:String(Date.now()+3600000)}),{mode:0o600,flag:'wx'});
console.log(JSON.stringify({target,name}));
