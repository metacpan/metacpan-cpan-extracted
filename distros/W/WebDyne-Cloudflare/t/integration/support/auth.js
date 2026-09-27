import {timingSafeEqual} from "node:crypto";

export function authenticated(request, env) {
  if (!/^[a-f0-9]{64}$/.test(env.PROTOTYPE_TOKEN ?? "")) return false;
  const expiry = Number(env.PROTOTYPE_EXPIRES);
  if (!Number.isFinite(expiry) || Date.now() >= expiry) return false;
  const expected = Buffer.from(`Bearer ${env.PROTOTYPE_TOKEN}`);
  const actual = Buffer.from(request.headers.get("authorization") ?? "");
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
