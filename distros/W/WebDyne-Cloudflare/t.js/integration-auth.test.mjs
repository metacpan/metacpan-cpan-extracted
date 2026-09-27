import assert from "node:assert/strict";
import test from "node:test";
import {authenticated} from "../t/integration/support/auth.js";

test("deployment authentication fails closed and respects expiry", () => {
  const token = 'a'.repeat(64);
  const env = {PROTOTYPE_TOKEN: token, PROTOTYPE_EXPIRES: String(Date.now() + 60_000)};
  const request = (value) => new Request('https://example.test/health', {headers: value ? {authorization: value} : {}});
  assert.equal(authenticated(request(`Bearer ${token}`), env), true);
  assert.equal(authenticated(request(), env), false);
  assert.equal(authenticated(request(`Bearer ${'b'.repeat(64)}`), env), false);
  assert.equal(authenticated(request(`Bearer ${token}`), {}), false);
  assert.equal(authenticated(request(`Bearer ${token}`), {...env, PROTOTYPE_EXPIRES: '0'}), false);
  assert.equal(authenticated(request(`Bearer ${token}`), {...env, PROTOTYPE_EXPIRES: 'invalid'}), false);
});
