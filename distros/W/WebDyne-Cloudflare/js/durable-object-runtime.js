import { createWebDyneCloudflareExtension } from "./cloudflare.js";
import { encodeValue, decodeValue, methodName, wire, errorResponse } from "./durable-object-codec.js";

/** Cloudflare class construction stays injectable for host-level tests. */
export function createDurableObjectClass({ DurableObject, createRuntime, runtimeOptions, definition, extensionOptions = {}, createExtensions = () => [createWebDyneCloudflareExtension(extensionOptions)] }) {
  if (!/^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*$/.test(definition?.perlPackage ?? "")) throw new TypeError("Invalid Durable Object Perl package");
  if (!Array.isArray(definition.methods) || !definition.methods.length) throw new TypeError("Durable Object methods must be a non-empty array");
  const methods = definition.methods.map(methodName);
  if (new Set(methods).size !== methods.length) throw new TypeError("Duplicate Durable Object methods");
  if (definition.initialize !== undefined && typeof definition.initialize !== "boolean") throw new TypeError("initialize must be boolean");
  const allowed = new Set(methods);
  class PerlDurableObject extends DurableObject {
    #runtime;
    #ready = false;
    #queue = Promise.resolve();
    #pending = 0;
    async webdyneInvoke(request) {
      try {
        wire(request);
        if (request?.version !== 1 || !allowed.has(request.method)) throw new Error("Durable Object method is not exposed");
        if (!Array.isArray(request.chain) || request.chain.length > 32
          || request.chain.some(id => typeof id !== "string" || !/^[a-f0-9]{64}$/.test(id))) throw new TypeError("Invalid Durable Object call chain");
        const id = this.ctx.id.toString();
        if (request.chain.includes(id)) throw new Error("Durable Object call cycle or same-object re-entry rejected");
        if (!Array.isArray(decodeValue(request.args))) throw new TypeError("RPC arguments must be an array");
        if (this.#pending >= 64) throw new Error("Durable Object invocation queue is full");
        this.#pending++;
        const task = this.#queue.then(async () => {
          const chain = [...request.chain, id];
          const invocation = { durableObject: { id, chain, storage: this.ctx.storage } };
          if (!this.#runtime) {
            this.#runtime = createRuntime({ ...runtimeOptions, mode: "invocation",
              extensions: createExtensions() });
          }
          const invoke = (method, args) => this.#runtime.invoke({
            bindings: this.env, invocation,
            entrypoint: "WebDyne::Cloudflare::DurableObject::Handler::application",
            scope: { type: "webdyne.invocation", package: definition.perlPackage, method, args },
          });
          try {
            if (!this.#ready) {
              if (definition.initialize) {
                const initialized = await invoke("initialize", encodeValue([]));
                if (!initialized.ok) return initialized;
              }
              this.#ready = true;
            }
            const result = await invoke(request.method, request.args);
            wire(result);
            return result;
          } catch (error) {
            // A failed runtime or cleanup cannot retain initialized Perl state.
            const failedRuntime = this.#runtime;
            this.#runtime = undefined;
            this.#ready = false;
            try { await failedRuntime?.dispose?.(); }
            catch (cleanupError) { throw new AggregateError([error, cleanupError], "Object runtime retirement failed"); }
            throw error;
          }
        });
        this.#queue = task.catch(() => undefined);
        try { return await task; } finally { this.#pending--; }
      } catch (error) { return errorResponse(error); }
    }
  }
  // Explicit native RPC methods are also usable by ordinary JavaScript clients.
  for (const method of methods) Object.defineProperty(PerlDurableObject.prototype, method, {
    value: async function(...args) {
      const response = await this.webdyneInvoke({ version: 1, method, args: encodeValue(args), chain: [] });
      if (!response.ok) {
        const error = new Error(response.error.message);
        error.name = response.error.name;
        error.code = response.error.code;
        throw error;
      }
      return decodeValue(response.result);
    },
  });
  return PerlDurableObject;
}
