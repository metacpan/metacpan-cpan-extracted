#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile, stat, writeFile } from "node:fs/promises";
import { basename, resolve } from "node:path";

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
for (const required of ["tarball", "destination", "revision", "dirty"]) {
  if (!configured[required]) throw new Error(`Missing --${required}`);
}
if (!/^[0-9a-f]{40}$/.test(configured.revision)) throw new Error("--revision must be a complete Git commit SHA");
if (!/^(?:true|false)$/.test(configured.dirty)) throw new Error("--dirty must be true or false");

const packageJson = JSON.parse(await readFile(resolve("package.json"), "utf8"));
const tarball = resolve(configured.tarball);
const bytes = await readFile(tarball);
const details = await stat(tarball);
const manifest = {
  schemaVersion: 1,
  package: {
    name: packageJson.name,
    version: packageJson.version,
  },
  source: {
    repository: "https://github.com/aspeer/pm-WebDyne-Cloudflare",
    revision: configured.revision,
    dirty: configured.dirty === "true",
  },
  artifact: {
    filename: basename(tarball),
    bytes: details.size,
    sha256: createHash("sha256").update(bytes).digest("hex"),
  },
};
await writeFile(resolve(configured.destination), `${JSON.stringify(manifest, null, 2)}\n`);
