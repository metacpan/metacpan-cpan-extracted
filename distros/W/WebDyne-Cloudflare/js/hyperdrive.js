import { createWebDyneCloudflareExtension } from "./cloudflare.js";
import { createPgClient } from "./hyperdrive-pg.js";
import { postgresProtocol } from "./hyperdrive-postgres.js";
import { createMysqlClient, mysqlProtocol } from "./hyperdrive-mysql.js";

export function hyperdriveProtocol(connectionString) {
  const scheme = new URL(connectionString).protocol;
  if (["postgres:", "postgresql:"].includes(scheme)) return postgresProtocol;
  if (scheme === "mysql:") return mysqlProtocol;
  throw new TypeError("Unsupported Hyperdrive connection scheme");
}

function createClient(options) {
  return hyperdriveProtocol(options.connectionString) === mysqlProtocol
    ? createMysqlClient(options) : createPgClient(options);
}

// Select this entry point only in Workers with nodejs_compat enabled.
export function createWebDyneHyperdriveExtension(options = {}) {
  return createWebDyneCloudflareExtension({ ...options,
    hyperdriveProtocolFactory: options.hyperdriveProtocolFactory ?? hyperdriveProtocol,
    hyperdriveClientFactory: options.hyperdriveClientFactory ?? createClient });
}
export { HyperdriveHostBridge, HYPERDRIVE_DEFAULT_LIMITS } from "./hyperdrive-host.js";
