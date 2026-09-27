import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {readFile,writeFile} from 'node:fs/promises';
const [base,secretPath,resultPath]=process.argv.slice(2);
if(!resultPath)throw new Error('Usage: smoke.mjs WORKER_URL SECRET_FILE RESULT_FILE');
const secret=JSON.parse(await readFile(secretPath,'utf8')).PROTOTYPE_TOKEN;
const report={started:new Date().toISOString(),cases:[]};
const call=(path,options={})=>fetch(new URL(path,base),{headers:{authorization:`Bearer ${secret}`},signal:AbortSignal.timeout(45000),...options});
const json=async(path,options)=>{const response=await call(path,options);const text=await response.text();assert.equal(response.status,200,text);return JSON.parse(text);};
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
assert.equal((await fetch(new URL('/health',base))).status,401);
assert.equal((await call('/health',{headers:{authorization:'Bearer bad'}})).status,401);
report.auth=true;
try {
  for(const route of ['/run','/sql','/limits','/network','/sequence','/abort']) {
    const token=randomUUID();const item={route,token};report.cases.push(item);
    try {
      if(route==='/abort') {
        const controller=new AbortController(); const response=await call(`/abort?token=${token}`,{signal:controller.signal,headers:{authorization:`Bearer ${secret}`,accept:'text/event-stream'}});
        assert.equal(response.status,200);
        const reader=response.body.getReader();let text='';
        while(!text.includes('\n\n')) {const part=await reader.read();assert.equal(part.done,false);text+=new TextDecoder().decode(part.value);}
        const {pid}=JSON.parse(text.split('\n').find(line=>line.startsWith('data:')).slice(5).trim());let active=false;
        for(let attempt=0;attempt<15;attempt++) {
          const activity=await json(`/activity?token=${token}&pid=${pid}`);
          if(activity.some(row=>row.state==='active'&&row.wait==='PgSleep')){active=true;break;}
          await sleep(50);
        }
        assert.ok(active,'sleep query must be active before cancelling');item.activeSleepObserved=true;
        controller.abort();await reader.cancel().catch(()=>{});
        let rows=[];
        for(let attempt=0;attempt<50;attempt++) {
          rows=await json(`/verify?token=${token}`);
          if(rows.some(row=>row.slot===9000))break;
          await sleep(200);
        }
        assert.equal(rows.length,1,'only completion evidence may remain');
        assert.equal(rows[0].slot,9000);item.completion=JSON.parse(rows[0].value);
        assert.deepEqual(item.completion,{status:'rejected',aborted:true});
      } else {
        const result=await json(`${route}?token=${token}`);item.result=result;
        if(route==='/sequence') {
          assert.deepEqual(result.map(row=>row.path),['/prime','/stale','/failure','/health']);
          assert.equal(JSON.parse(result[0].body).primed,1);assert.equal(JSON.parse(result[1].body).stale,1);
          assert.equal(result[2].completion,'rejected');assert.equal(JSON.parse(result[3].body).fresh_interpreter,1);
        } else {
          assert.equal(result.status,200,result.body);assert.equal(result.completion,'fulfilled',result.body);
          const body=JSON.parse(result.body);
          if(route==='/run')assert.deepEqual(body,{typed:1,fixture:1,statement:1,crud:1,transactions:1,disconnect:1});
          if(route==='/sql')assert.deepEqual(body,{joins:1,returning:1,binding:1,types:1});
          if(route==='/limits')assert.deepEqual(body,{rows:1,bytes:1,timeout:1,connections:1});
          if(route==='/network')assert.equal(body.recovered,1);
        }
        assert.deepEqual(await json(`/verify?token=${token}`),route==='/run'?[{slot:1,value:'committed'}]:[]);
      }
      item.passed=true;
    } catch(error) {item.error=String(error);}
    finally {
      item.cleanup=await json(`/cleanup?token=${token}`,{method:'POST'});
      assert.deepEqual(await json(`/verify?token=${token}`),[]);item.cleanupVerified=true;
      await writeFile(resultPath,JSON.stringify(report,null,2)+'\n');
    }
  }
  report.concurrentRecovery=await Promise.all(Array.from({length:4},async()=>{
    const result=await json(`/health?token=${randomUUID()}`);assert.equal(result.status,200,result.body);
    assert.equal(JSON.parse(result.body).fresh_interpreter,1);return true;
  }));
} finally {report.finished=new Date().toISOString();await writeFile(resultPath,JSON.stringify(report,null,2)+'\n');}
console.log(JSON.stringify(report));
assert.ok(report.cases.every(item=>item.passed),'one or more qualification cases failed');
