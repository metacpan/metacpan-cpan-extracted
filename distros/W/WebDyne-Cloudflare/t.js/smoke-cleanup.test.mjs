import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import test from "node:test";

const execute = promisify(execFile);

for (const service of ["kv", "r2"]) {
  test(`${service} smoke fails when cleanup fails`, async () => {
    const runner = new URL(`./smoke-${service}.mjs`, import.meta.url).href;
    const program = `
      process.argv = [process.execPath, "smoke", "http://local.invalid/"];
      globalThis.fetch = async (url) => {
        const action = url.searchParams.get("action");
        return {
          status: action === "delete" ? 500 : 200,
          text: async () => "${service.toUpperCase()} smoke OK: " + action,
        };
      };
      await import(${JSON.stringify(runner)});
    `;
    await assert.rejects(execute(process.execPath, ["--input-type=module", "-e", program]), (error) => {
      assert.equal(error.code, 1);
      assert.match(error.stderr, /delete returned 500/);
      assert.doesNotMatch(error.stdout, /operations and cleanup/);
      return true;
    });
  });
}
