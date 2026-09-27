import assert from "node:assert/strict";

export async function requestAction(baseUrl, route, action, key) {
  const url = new URL(route, baseUrl);
  url.searchParams.set("action", action);
  url.searchParams.set("key", key);
  const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  const body = await response.text();
  assert.equal(response.status, 200, `${action} returned ${response.status}: ${body.slice(0, 500)}`);
  assert.match(body, new RegExp(`${route.startsWith("/kv") ? "KV" : "R2"} smoke OK: ${action}`));
  return body;
}

export async function retryAction(baseUrl, route, action, key, attempts = 20) {
  let error;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return await requestAction(baseUrl, route, action, key);
    } catch (caught) {
      error = caught;
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }
  throw error;
}
