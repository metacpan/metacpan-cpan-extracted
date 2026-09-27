// Use the same local port as compose.yaml; invoke through npm run check:local/dev:local.
import {spawn} from 'node:child_process';
const [command,...args]=process.argv.slice(2);
if (!['check','dev'].includes(command) || !process.env.npm_execpath) {
    throw new Error('Use npm run check:local or npm run dev:local');
}
const port=process.env.DB_PORT || '13306';
if (!/^\d+$/.test(port) || Number(port)<1 || Number(port)>65535) {
    throw new Error('DB_PORT must be a TCP port between 1 and 65535');
}
const child=spawn(process.execPath,[process.env.npm_execpath,'run',command,'--',...args],{
    stdio:'inherit',
    env:{...process.env,CLOUDFLARE_HYPERDRIVE_LOCAL_CONNECTION_STRING_DB:
        `mysql://webdyne:local-demo-only@127.0.0.1:${port}/webdyne_demo`},
});
for (const signal of ['SIGINT','SIGTERM']) process.on(signal,()=>child.kill(signal));
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',(code,signal)=>{process.exitCode=code ?? (signal==='SIGINT'?130:1);});
