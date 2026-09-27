# Secrets Store example

## Quick start

Requires Node.js 24+ and npm. From the repository root, copy this example into a
new directory and work there:

```sh
cp -R examples/secrets-store /tmp/webdyne-secrets-store-example
cd /tmp/webdyne-secrets-store-example
npm install
npm run check
npm run setup:local
npm run dev
```

Open the local URL printed by Wrangler (normally `http://localhost:8787/`).
Stop the Worker with Ctrl-C.

These examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+,
installed from npm by `npm install`.

## What to expect

`check` builds and dry-runs the Worker, creating `.webdyne/wrangler.jsonc`.
`setup:local` then rebuilds the Worker artifacts and creates a dummy secret in
Wrangler's local store using that configuration. It explicitly selects
`--remote=false`, needs no login, and uses the fixed non-secret test value
`webdyne-test-dummy-do-not-render`. The store ID and name match package.json.
The setup command can be rerun after `check`; it restores the dummy value for
this local demo. Local persistence lives in `.wrangler`.

The default WebDyne page renders `Secret retrieval succeeded`. It never returns
the value or its length, and its cache policy includes `no-store`.

To run the native PAGI supplement, stop the Worker and run:

```sh
npm pkg set webdyne.entry=app.pagi
npm run dev
```

It returns the same confirmation as plain text. Switch back with
`npm pkg set webdyne.entry=app.psp` and restart. Both variants share local storage.

For production, configure your existing account secret and binding deliberately;
`setup:local` is only for this local demo. See the
[Secrets Store API](../../lib/WebDyne/Cloudflare/SecretsStore.pm.md).
