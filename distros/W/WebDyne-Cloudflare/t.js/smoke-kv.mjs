#!/usr/bin/env node

import { randomUUID } from "node:crypto";
import { requestAction, retryAction } from "./smoke-support.mjs";

const baseUrl = process.argv[2] ?? "http://127.0.0.1:8790/";
const key = `webdyne-smoke:${randomUUID()}`;

try {
  await requestAction(baseUrl, "/kv.psp", "put", key);
  await retryAction(baseUrl, "/kv.psp", "get", key);
  await retryAction(baseUrl, "/kv.psp", "list", key);
  await requestAction(baseUrl, "/kv.psp", "put_json", key);
  await retryAction(baseUrl, "/kv.psp", "get_json", key);
  await requestAction(baseUrl, "/kv.psp", "put_bytes", key);
  await retryAction(baseUrl, "/kv.psp", "get_bytes", key);
} finally {
  await retryAction(baseUrl, "/kv.psp", "delete", key, 3);
}

console.log("WebDyne KV smoke OK (operations and cleanup)");
