#!/usr/bin/env node

import { randomUUID } from "node:crypto";
import { requestAction } from "./smoke-support.mjs";

const baseUrl = process.argv[2] ?? "http://127.0.0.1:8790/";
const key = `webdyne-smoke/${randomUUID()}.bin`;

try {
  await requestAction(baseUrl, "/r2.psp", "put", key);
  await requestAction(baseUrl, "/r2.psp", "get", key);
  await requestAction(baseUrl, "/r2.psp", "head", key);
  await requestAction(baseUrl, "/r2.psp", "list", key);
} finally {
  await requestAction(baseUrl, "/r2.psp", "delete", key);
}

console.log("WebDyne R2 smoke OK (operations and cleanup)");
