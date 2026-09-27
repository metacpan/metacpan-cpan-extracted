import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const workflow = readFileSync(new URL("../.github/workflows/webdyne-cloudflare-npm.yml", import.meta.url), "utf8");

function step(name) {
  const source = workflow.split(`      - name: ${name}\n`)[1]?.split("\n      - name:")[0];
  assert.ok(source, `Missing workflow step: ${name}`);
  return source;
}

test("npm workflow uses pinned staging-capable npm and OIDC without a token fallback", () => {
  assert.match(step("Install npm with staged-publishing support"), /npm install --global npm@11\.17\.0 --ignore-scripts/);
  assert.match(workflow, /id-token: write/);
  assert.doesNotMatch(workflow, /NPM_TOKEN|NODE_AUTH_TOKEN/);
  assert.match(workflow, /--source-ref refs\/heads\/main --source-digest "\$GITHUB_SHA"/);
});

test("npm workflow only stages the exact archive and never directly publishes or approves", () => {
  for (const line of workflow.matchAll(/^\s*run: (npm .+)$/gm)) {
    assert.match(line[1], /^npm stage publish /);
  }
  for (const [name, flag] of [
    ["Dry-run npm staging", "--dry-run"],
    ["Stage on npm with Trusted Publishing", "--provenance"],
  ]) {
    const command = step(name).trim().replace(/^run: /, "");
    // A shell function intercepts npm; no registry calls are made.
    const output = execFileSync("bash", ["-euo", "pipefail", "-c",
      `npm() { printf '%s\\n' "$@"; }\n${command}`,
    ], { env: { ...process.env, TARBALL_NAME: "qualified release.tgz" }, encoding: "utf8" });
    assert.deepEqual(output.trim().split("\n"), [
      "stage", "publish", "./incoming/qualified release.tgz", "--access", "public", flag, "--ignore-scripts",
    ]);
    assert.throws(() => execFileSync("bash", ["-euo", "pipefail", "-c",
      `npm() { return 42; }\n${command}`,
    ], { env: { ...process.env, TARBALL_NAME: "qualified.tgz" }, stdio: "pipe" }),
    (error) => error.status === 42);
  }
});

test("successful staging reports pending MFA approval, not completed publication", () => {
  const directory = mkdtempSync(join(tmpdir(), "webdyne-staging-summary-"));
  try {
    const summary = join(directory, "summary.md");
    const source = step("Report pending maintainer approval");
    assert.doesNotMatch(source, /if:.*always/);
    const command = source.split("        run: |\n")[1].replace(/^          /gm, "");
    execFileSync("bash", ["-euo", "pipefail", "-c", command], {
      env: { ...process.env, GITHUB_STEP_SUMMARY: summary, PACKAGE_VERSION: "9.8.7" },
    });
    const content = readFileSync(summary, "utf8");
    assert.match(content, /Awaiting MFA approval/);
    assert.match(content, /@webdyne\/webdyne-cloudflare@9\.8\.7; it is not public yet/);
    assert.match(content, /Approval is deliberately not automated/);
    assert.doesNotMatch(workflow, /name: Verify published version/);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
