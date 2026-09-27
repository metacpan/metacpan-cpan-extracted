#!/usr/bin/env node
import assert from "node:assert/strict";

// Run against the local examples/secrets-store application with a dummy secret.
const url = process.argv[2] ?? "http://127.0.0.1:8793/";
const responses = await Promise.all(Array.from({ length: 4 }, () => fetch(url)));
for (const response of responses) {
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(await response.text(), "Secret retrieval succeeded\n");
}
console.log("Secrets Store Worker/Perl smoke OK (four requests, fixed non-secret response)");
