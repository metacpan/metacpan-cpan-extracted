import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
const [base,secretPath,resultPath]=process.argv.slice(2);
if(!resultPath)throw new Error('Usage: smoke.mjs WORKER_URL SECRET_FILE RESULT_FILE');
const secret=JSON.parse(await readFile(secretPath,'utf8')).PROTOTYPE_TOKEN;
assert.equal((await fetch(base)).status,401);
const report={started:new Date().toISOString(),auth:true,cases:[]};
async function run(route) {
 const response=await fetch(new URL(route+'?token='+crypto.randomUUID(),base),{headers:{authorization:`Bearer ${secret}`},signal:AbortSignal.timeout(45000)});
 assert.equal(response.status,200);const result=await response.json();
 assert.equal(result.status,route==='/failure'?500:200,result.body);
 assert.equal(result.completion,route==='/failure'?'rejected':'fulfilled');assert.equal(result.verified,true,JSON.stringify(result));
 return {route,...result};
}
try {
 for(const route of ['/','/limits','/failure','/'])report.cases.push(await run(route));
 report.concurrent=await Promise.all(Array.from({length:3},()=>run('/')));
}finally{report.finished=new Date().toISOString();await writeFile(resultPath,JSON.stringify(report,null,2)+'\n');}
console.log(JSON.stringify(report));
