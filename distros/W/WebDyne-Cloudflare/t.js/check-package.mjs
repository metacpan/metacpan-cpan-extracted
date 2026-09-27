#!/usr/bin/env node

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execute = promisify(execFile);
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const packageJson = JSON.parse(await readFile(join(root, "package.json"), "utf8"));
const cache = await mkdtemp(join(tmpdir(), "webdyne-cloudflare-npm-cache-"));

const expected = [
  "js/durable-object.js",
  "js/durable-object-runtime.js",
  "js/durable-object-host.js",
  "js/durable-object-codec.js",
  "lib/WebDyne/Cloudflare/DurableObject.pm",
  "lib/WebDyne/Cloudflare/DurableObject/Context.pm",
  "lib/WebDyne/Cloudflare/DurableObject/Handler.pm",
  "lib/WebDyne/Cloudflare/DurableObject/Error.pm",
  "lib/WebDyne/Cloudflare/DurableObject/Bytes.pm",

  "js/secrets-store-host.js",
  "lib/WebDyne/Cloudflare/SecretsStore.pm",
  "lib/WebDyne/Cloudflare/SecretsStore/Error.pm",
  "LICENSE",
  "README.md",
  "TEST.md",
  "docs/configuration.md",
  "docs/releasing.md",
  "docs/qualification.md",
  "js/cloudflare.js",
  "js/d1-host.js",
  "js/kv-host.js",
  "js/r2-host.js",
  "js/storage-host.js",
  "js/hyperdrive.js",
  "js/hyperdrive-host.js",
  "js/hyperdrive-codec.js",
  "js/hyperdrive-pg.js",
  "js/hyperdrive-postgres.js",
  "js/hyperdrive-mysql.js",
  "lib/WebDyne/Cloudflare/Hyperdrive.pm",
  "lib/WebDyne/Cloudflare/Hyperdrive/Statement.pm",
  "lib/WebDyne/Cloudflare/Hyperdrive/Blob.pm",
  "lib/WebDyne/Cloudflare/Hyperdrive/Error.pm",
  "lib/WebDyne/Cloudflare/Hyperdrive/Codec.pm",
  "lib/WebDyne/Cloudflare/Hyperdrive/Transport.pm",

  "lib/WebDyne/Cloudflare.pm",
  "lib/WebDyne/Cloudflare/D1.pm",
  "lib/WebDyne/Cloudflare/D1/Session.pm",
  "lib/WebDyne/Cloudflare/D1/Blob.pm",
  "lib/WebDyne/Cloudflare/D1/Error.pm",
  "lib/WebDyne/Cloudflare/D1/Statement.pm",
  "lib/WebDyne/Cloudflare/KV.pm",
  "lib/WebDyne/Cloudflare/KV/Blob.pm",
  "lib/WebDyne/Cloudflare/KV/Error.pm",
  "lib/WebDyne/Cloudflare/R2.pm",
  "lib/WebDyne/Cloudflare/R2/Blob.pm",
  "lib/WebDyne/Cloudflare/R2/Error.pm",
  "lib/WebDyne/Cloudflare/R2/Object.pm",
  "package.json",
  "webdyne-extension.json",
];
expected.push(...expected.filter((path) => path.endsWith(".pm")).map((path) => `${path}.md`));
expected.sort();

try {
  assert.equal(packageJson.name, "@webdyne/webdyne-cloudflare");
  assert.match(packageJson.version, /^\d+\.\d+\.\d+$/);
  assert.equal(packageJson.private, undefined);
  const { stdout } = await execute(
    "npm",
    ["pack", "--dry-run", "--json", "--ignore-scripts", "--cache", cache],
    { cwd: root, maxBuffer: 1024 * 1024 },
  );
  const [packed] = JSON.parse(stdout);
  assert.equal(packed.id, `${packageJson.name}@${packageJson.version}`);
  assert.deepEqual(packed.files.map(({ path }) => path).sort(), expected);
  console.log(`Validated ${packed.id}: ${packed.entryCount} files, ${packed.size} packed bytes`);
} finally {
  await rm(cache, { recursive: true, force: true });
}
