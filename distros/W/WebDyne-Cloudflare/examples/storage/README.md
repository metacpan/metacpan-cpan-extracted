# D1, KV and R2 WebDyne pages

## Quick start

Requires Node.js 24+ and npm. From the repository root, copy this example into a
new directory and work there:

```sh
cp -R examples/storage /tmp/webdyne-storage-example
cd /tmp/webdyne-storage-example
npm install
npm run check
npx wrangler d1 execute DB --local --config .webdyne/wrangler.jsonc --file schema.sql
npm run dev
```

Open the local URL printed by Wrangler (normally `http://localhost:8787/`).
Stop the Worker with Ctrl-C.

These examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+,
installed from npm by `npm install`.

## What to expect

Open `/d1.psp`, `/d1-api/row/1`, `/kv.psp`, and `/r2.psp`. D1 reads a seeded row
and exposes a WebDyne JSON API. KV/R2 write a fixed greeting only on form submission.
These pages demonstrate HTML escaping and separately bound SQL parameters.

`perl tools/stage-worker.pl NEW_DIRECTORY` from the repository stages this storage
application into a fresh directory. Its configuration comes from package.json;
there is no second, partially configured Wrangler file to maintain.

Replace placeholders with your resources before remote deployment. KV is
eventually consistent. These examples are independent of the full storage smoke
fixtures under `t/fixtures/app`.
