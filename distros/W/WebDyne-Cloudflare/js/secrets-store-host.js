import { createCapability, scopeExtensions, storageBindingNames } from "./storage-host.js";

const EXTENSION_NAME = "webdyne.cloudflare.secrets_store";
const HOST_FUNCTION_NAME = "WebDyne::Cloudflare::SecretsStore::Host::call";
const PROTOCOL_VERSION = 1;

// Only errors created here may cross the bridge; provider errors can contain secrets.
class SecretsStoreError extends Error {
  constructor(name, message) { super(message); this.name = name; }
}
function fail(name, message) { throw new SecretsStoreError(name, message); }

export function secretsStoreBindingNames(value) {
  return storageBindingNames(value, "Secrets Store");
}

export class SecretsStoreHostBridge {
  #capabilities = new Map();
  #registeredPerls = new WeakSet();
  #tokenFactory;

  constructor({ tokenFactory = () => crypto.randomUUID() } = {}) {
    this.#tokenFactory = tokenFactory;
  }

  attachScope(scope, env, bindingNames) {
    const extensions = scopeExtensions(scope, "Secrets Store");
    const names = secretsStoreBindingNames(bindingNames);
    if (!names.length) return { release() {} };
    const bindings = new Map();
    for (const name of names) {
      if (!Object.hasOwn(env ?? {}, name) || typeof env[name]?.get !== "function") {
        throw new Error(`Configured Secrets Store binding ${name} is unavailable`);
      }
      bindings.set(name, env[name]);
    }
    if (extensions[EXTENSION_NAME]) throw new Error(`PAGI extension ${EXTENSION_NAME} is already present`);
    const capability = createCapability(this.#capabilities, this.#tokenFactory, "Secrets Store");
    this.#capabilities.set(capability, bindings);
    extensions[EXTENSION_NAME] = { version: PROTOCOL_VERSION, capability, bindings: names };
    let released = false;
    return {
      release: () => {
        if (released) return;
        released = true;
        // Clear binding references as well as revoking the token, including during pending reads.
        bindings.clear();
        this.#capabilities.delete(capability);
        if (extensions[EXTENSION_NAME]?.capability === capability) delete extensions[EXTENSION_NAME];
      },
    };
  }

  register(perl) {
    if (this.#registeredPerls.has(perl)) return;
    perl.registerFunction(HOST_FUNCTION_NAME, async requestValue => {
      let response;
      try {
        let request;
        try { request = JSON.parse(requestValue.toString()); }
        catch { fail("SECRETS_STORE_PROTOCOL_ERROR", "Invalid Secrets Store request"); }
        response = { ok: true, result: await this.dispatch(request) };
      } catch (error) {
        response = { ok: false, error: error instanceof SecretsStoreError
          ? { name: error.name, message: error.message }
          : { name: "SECRETS_STORE_ERROR", message: "Secrets Store request failed" } };
      }
      return perl.createString(JSON.stringify(response));
    });
    this.#registeredPerls.add(perl);
  }

  async dispatch(request) {
    if (!request || typeof request !== "object" || Array.isArray(request)
      || request.version !== PROTOCOL_VERSION
      || Object.keys(request).some(key => !["version", "capability", "binding", "operation"].includes(key))) {
      fail("SECRETS_STORE_PROTOCOL_ERROR", "Invalid Secrets Store request");
    }
    const bindings = this.#capabilities.get(request.capability);
    if (!bindings) fail("SECRETS_STORE_CAPABILITY_ERROR", "Secrets Store capability is invalid or has expired");
    if (!bindings.has(request.binding)) fail("SECRETS_STORE_BINDING_ERROR", "Secrets Store binding is not available to this request");
    if (request.operation !== "get") fail("SECRETS_STORE_PROTOCOL_ERROR", "Unsupported Secrets Store operation");
    let value;
    try { value = await bindings.get(request.binding).get(); }
    catch { fail("SECRETS_STORE_READ_ERROR", "Secrets Store retrieval failed"); }
    if (this.#capabilities.get(request.capability) !== bindings) {
      fail("SECRETS_STORE_CAPABILITY_ERROR", "Secrets Store capability expired during retrieval");
    }
    if (typeof value !== "string") fail("SECRETS_STORE_PROTOCOL_ERROR", "Secrets Store returned an invalid value");
    return value;
  }
}

export {
  EXTENSION_NAME as SECRETS_STORE_EXTENSION_NAME,
  HOST_FUNCTION_NAME as SECRETS_STORE_HOST_FUNCTION_NAME,
};
