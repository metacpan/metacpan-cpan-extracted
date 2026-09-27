# D1 sessions and bookmarks

## Quick start

Requires Node.js 24+ and npm. From the repository root, copy this example into a
new directory and work there:

```sh
cp -R examples/d1-sessions /tmp/webdyne-d1-sessions-example
cd /tmp/webdyne-d1-sessions-example
npm install
npm run check
npm run dev
```

Open the local URL printed by Wrangler (normally `http://localhost:8787/`).
Stop the Worker with Ctrl-C.

These examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+,
installed from npm by `npm install`.

## What to expect

The default WebDyne page executes read-only `SELECT 7` through a session and
carries its next bookmark in a hidden form field and `x-d1-bookmark` response
header. Submit the form to continue that session. A request with no bookmark
starts with `first-primary`. No schema or write is needed.

The [native PAGI alternative](../README.md#native-pagi-alternatives) returns
D1 results and metadata as JSON. Send its `x-d1-bookmark` response header back
on the next request. Local D1 may return no bookmark and cannot prove remote
replica routing or lag. Before remote testing, replace the placeholder database
ID and enable read replication in that database's Cloudflare settings.

See [D1 sessions](../../lib/WebDyne/Cloudflare/D1.pm.md#sessions-and-read-replication)
for consistency choices. Neither variant retains a session object across requests.
