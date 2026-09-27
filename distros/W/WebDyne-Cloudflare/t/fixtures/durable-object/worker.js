import generated, { Counter, runtimeMemory } from './.webdyne/worker.js';
export { Counter };
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === '/memory') return Response.json(runtimeMemory());
    if (url.pathname === '/call') {
      const {name,method,args=[]} = await request.json();
      const stub=env.COUNTERS.getByName(name);
      try { return Response.json({ok:true,result:await stub[method](...args)}); }
      catch(error) {return Response.json({ok:false,error:{name:error.name,message:error.message,code:error.code}});}
    }
    return generated.fetch(request,env,ctx);
  },
};
