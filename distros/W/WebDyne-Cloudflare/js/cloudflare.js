import { DurableObjectHostBridge, durableObjectBindingNames } from "./durable-object-host.js";
import { SecretsStoreHostBridge, secretsStoreBindingNames } from "./secrets-store-host.js";
import { D1HostBridge, d1BindingNames } from "./d1-host.js";
import { KVHostBridge, kvBindingNames } from "./kv-host.js";
import { R2HostBridge, r2BindingNames } from "./r2-host.js";
import { HyperdriveHostBridge, hyperdriveBindingNames } from "./hyperdrive-host.js";

function configuredBindingNames(options, name, fallback) {
  return options[name] === undefined ? undefined : fallback(options[name]);
}

function releaseAll(attachments) {
  let released = false;
  let completion;
  return {
    release(context) {
      if (released) return completion;
      released = true;
      const errors = [];
      const pending = [];
      for (const attachment of attachments.reverse()) {
        try {
          const result = attachment.release(context);
          if (result && typeof result.then === "function") pending.push(result);
        } catch (error) {
          errors.push(error);
        }
      }
      if (pending.length) {
        completion = Promise.allSettled(pending).then(results => {
          errors.push(...results.filter(result => result.status === "rejected").map(result => result.reason));
          if (errors.length === 1) throw errors[0];
          if (errors.length > 1) throw new AggregateError(errors, "Cloudflare capability cleanup failed");
        });
        return completion;
      }
      if (errors.length === 1) throw errors[0];
      if (errors.length > 1) throw new AggregateError(errors, "Cloudflare capability cleanup failed");
    },
  };
}

/**
 * Create the Cloudflare side of the WebDyne extension lifecycle.
 *
 * Binding names are fixed by application configuration when supplied. The
 * WEBDYNE_*_BINDINGS variables remain as compatibility paths for custom
 * Workers that instantiate this extension directly.
 */
export function createWebDyneCloudflareExtension(options = {}) {
  if (!options || typeof options !== "object" || Array.isArray(options)) {
    throw new TypeError("WebDyne Cloudflare extension options must be an object");
  }
  const configuredD1Bindings = configuredBindingNames(options, "d1Bindings", d1BindingNames);
  const configuredKVBindings = configuredBindingNames(options, "kvBindings", kvBindingNames);
  const configuredR2Bindings = configuredBindingNames(options, "r2Bindings", r2BindingNames);
  const configuredHyperdriveBindings = configuredBindingNames(options, "hyperdriveBindings", hyperdriveBindingNames);
  const configuredSecretsStoreBindings = configuredBindingNames(options, "secretsStoreBindings", secretsStoreBindingNames);
  const durableNames = configuredBindingNames(options, "durableObjectBindings", durableObjectBindingNames);
  const durableObject = new DurableObjectHostBridge({ nativeBindings: options.durableObjectNativeBindings });
  const secretsStore = new SecretsStoreHostBridge();
  const d1 = new D1HostBridge();
  const kv = new KVHostBridge({ maxValueBytes: options.kvMaxValueBytes });
  const r2 = new R2HostBridge({ maxObjectBytes: options.r2MaxObjectBytes });
  const hyperdrive = new HyperdriveHostBridge({ ...options.hyperdriveLimits, clientFactory: options.hyperdriveClientFactory, protocolFactory: options.hyperdriveProtocolFactory });

  return {
    name: "@webdyne/webdyne-cloudflare",

    register(perl) {
      durableObject.register(perl);
      secretsStore.register(perl);
      d1.register(perl);
      kv.register(perl);
      r2.register(perl);
      if (options.hyperdriveClientFactory || configuredHyperdriveBindings?.length) hyperdrive.register(perl);
    },

    attachScope({ scope, bindings, request, lifecycle, invocation }) {
      const attachments = [];
      try {
        attachments.push(durableObject.attachScope(scope, bindings, durableNames ?? [], invocation));
        attachments.push(secretsStore.attachScope(scope, bindings,
          configuredSecretsStoreBindings ?? secretsStoreBindingNames(bindings?.WEBDYNE_SECRETS_STORE_BINDINGS)));
        attachments.push(d1.attachScope(
          scope,
          bindings,
          configuredD1Bindings ?? d1BindingNames(bindings?.WEBDYNE_D1_BINDINGS),
        ));
        attachments.push(kv.attachScope(
          scope,
          bindings,
          configuredKVBindings ?? kvBindingNames(bindings?.WEBDYNE_KV_BINDINGS),
        ));
        attachments.push(r2.attachScope(
          scope,
          bindings,
          configuredR2Bindings ?? r2BindingNames(bindings?.WEBDYNE_R2_BINDINGS),
        ));
        attachments.push(hyperdrive.attachScope(scope, bindings,
          configuredHyperdriveBindings ?? hyperdriveBindingNames(bindings?.WEBDYNE_HYPERDRIVE_BINDINGS),
          { request, asyncCleanup: lifecycle?.asyncCleanup === true }));
      } catch (error) {
        try {
          releaseAll(attachments).release();
        } catch (cleanupError) {
          throw new AggregateError([error, cleanupError], "Cloudflare capability attachment failed during cleanup");
        }
        throw error;
      }
      return releaseAll(attachments);
    },
  };
}

export {
  D1HostBridge,
  D1_EXTENSION_NAME,
  D1_HOST_FUNCTION_NAME,
  d1BindingNames,
} from "./d1-host.js";
export {
  KVHostBridge,
  KV_DEFAULT_MAX_VALUE_BYTES,
  KV_EXTENSION_NAME,
  KV_HOST_FUNCTION_NAME,
  kvBindingNames,
} from "./kv-host.js";
export {
  R2HostBridge,
  R2_DEFAULT_MAX_OBJECT_BYTES,
  R2_EXTENSION_NAME,
  R2_HOST_FUNCTION_NAME,
  r2BindingNames,
} from "./r2-host.js";

export { SecretsStoreHostBridge, secretsStoreBindingNames,
  SECRETS_STORE_EXTENSION_NAME, SECRETS_STORE_HOST_FUNCTION_NAME } from "./secrets-store-host.js";
