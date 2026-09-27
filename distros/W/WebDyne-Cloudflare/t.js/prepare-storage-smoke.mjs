#!/usr/bin/env node

import { cp, mkdir, realpath, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function options(arguments_) {
  const result = {};
  for (let index = 0; index < arguments_.length; index += 2) {
    const name = arguments_[index];
    const value = arguments_[index + 1];
    if (!name?.startsWith("--") || value === undefined) throw new Error(`Invalid option near ${name ?? "end"}`);
    result[name.slice(2)] = value;
  }
  return result;
}

const configured = options(process.argv.slice(2));
for (const required of ["destination"]) {
  if (!configured[required]) throw new Error(`Missing --${required}`);
}
const destination = resolve(configured.destination);
const runtimeSource = configured["runtime-version"] ?? (configured["runtime-tarball"] ? pathToFileURL(await realpath(configured["runtime-tarball"])).href : "1.0.14");
const extensionSource = configured["extension-version"] ?? (configured["extension-tarball"] ? pathToFileURL(await realpath(configured["extension-tarball"])).href : "1.7.1");
const remote = configured.remote === "true";
const services = (configured.services ?? "d1,kv,r2").split(",").map((value) => value.trim()).filter(Boolean);
if (configured.remote !== undefined && !/^(?:true|false)$/.test(configured.remote)) {
  throw new Error("--remote must be true or false");
}
if (services.length === 0 || services.some((service) => !["d1", "kv", "r2"].includes(service))
  || new Set(services).size !== services.length) {
  throw new Error("--services must be a comma-separated subset of d1,kv,r2");
}
if (remote && services.includes("kv") && !configured["kv-namespace-id"]) {
  throw new Error("Remote KV smoke requires --kv-namespace-id");
}
if (remote && services.includes("r2") && !configured["r2-bucket-name"]) {
  throw new Error("Remote R2 smoke requires --r2-bucket-name");
}

if (remote && services.includes("d1") && !configured["d1-database-id"]) {
  throw new Error("Remote D1 smoke requires --d1-database-id");
}
await mkdir(destination);
await mkdir(resolve(destination, "app"));
for (const page of services.map((service) => `${service}.psp`)) {
  await cp(resolve(root, "t/fixtures/app", page), resolve(destination, "app", page));
}
if (services.includes("d1")) {
  await cp(resolve(root, "t/fixtures/app/d1-api.psp"), resolve(destination, "app/d1-api.psp"));
  await cp(resolve(root, "t/fixtures/app/d1-batch.psp"), resolve(destination, "app/d1-batch.psp"));
  await cp(resolve(root, "t/fixtures/schema.sql"), resolve(destination, "schema.sql"));
}
const packageJson = {
  name: "webdyne-cloudflare-storage-smoke",
  version: "1.0.0",
  private: true,
  type: "module",
  scripts: {
    build: "webdyne-cloudflare build",
    check: "webdyne-cloudflare check",
    dev: "webdyne-cloudflare dev",
  },
  dependencies: {
    "@webdyne/webdyne-cloudflare": extensionSource,
    "@webdyne/webdyne-zeroperl-5.44.0": runtimeSource,
  },
  webdyne: {
    entry: `${services[0]}.psp`,
    extensions: {
      "@webdyne/webdyne-cloudflare": {
        ...(services.includes("d1") ? { d1Bindings: ["DB"] } : {}),
        ...(services.includes("kv") ? { kvBindings: ["CACHE"] } : {}),
        ...(services.includes("r2") ? { r2Bindings: ["OBJECTS"] } : {}),
      },
    },
    cloudflare: {
      name: "webdyne-cloudflare-storage-smoke",
      ...(services.includes("d1") ? { d1Databases: [{
          binding: "DB",
          databaseName: "webdyne-cloudflare-smoke",
          databaseId: remote ? configured["d1-database-id"] : "00000000-0000-0000-0000-000000000001",
          ...(remote ? { remote: true } : {}),
        }] } : {}),
      ...(services.includes("kv") ? { kvNamespaces: [{
          binding: "CACHE",
          ...(remote ? { namespaceId: configured["kv-namespace-id"], remote: true } : {}),
        }] } : {}),
      ...(services.includes("r2") ? { r2Buckets: [{
          binding: "OBJECTS",
          ...(remote ? { bucketName: configured["r2-bucket-name"], remote: true } : {}),
        }] } : {}),
    },
  },
};
await writeFile(resolve(destination, "package.json"), `${JSON.stringify(packageJson, null, 2)}\n`);
console.log(JSON.stringify({ destination, remote, services, package: packageJson.name }));
