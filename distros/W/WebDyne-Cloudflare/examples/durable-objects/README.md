# WebDyne Durable Object counter

## Quick start

Requires Node.js 24+ and npm. From the repository root, copy this example into a
new directory and work there:

```sh
cp -R examples/durable-objects /tmp/webdyne-durable-objects-example
cd /tmp/webdyne-durable-objects-example
npm install
npm run check
npm run dev
```

Open the local URL printed by Wrangler (normally `http://localhost:8787/`).
Stop the Worker with Ctrl-C.

These examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+,
installed from npm by `npm install`.

## What to expect

Read the named `example` counter and submit the form to increment it. The default
`app/app.psp` is a WebDyne page; `lib/Example/Counter.pm` contains ordinary Perl
object handlers. The generated Worker exports `Counter` with SQLite storage.

The [native PAGI alternative](../README.md#native-pagi-alternatives) returns
JSON: GET reads the counter and POST increments it. Both clients use the same
object name, so switching clients preserves its value. Changing the name selects
an independent counter. Restarting the local Worker preserves Wrangler SQLite
state; deleting its `.wrangler` directory removes that local state.

Requires the finite-invocation runtime (1.0.13+); this example uses the qualified
1.0.14 baseline. Deployment creates a persistent namespace. Configure and review
your intended resource before deploying.

See the [handler sidecar](lib/Example/Counter.pm.md) and
[Durable Object API](../../lib/WebDyne/Cloudflare/DurableObject.pm.md) for context
lifetimes, explicit methods, SQL batches, limits and external objects.
