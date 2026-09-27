# MySQL Hyperdrive inventory

## Quick start

Requires Node.js 24+ and npm and Docker with Compose v2+ (`up --wait` support). From the repository root, copy this example into a
new directory and work there:

```sh
cp -R examples/hyperdrive-mysql /tmp/webdyne-hyperdrive-mysql-example
cd /tmp/webdyne-hyperdrive-mysql-example
npm install
npm run db:up
npm run check:local
npm run dev:local
```

Open the local URL printed by Wrangler (normally `http://localhost:8787/`).
Stop the Worker with Ctrl-C.

These examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+,
installed from npm by `npm install`.

## Local database

`db:up` starts the pinned official MySQL image, seeds `schema.sql` on the
first start, and waits until the inventory table can be queried. A two-line
Dockerfile copies the schema into the image, so this works without Docker host
file sharing. No application dependencies enter the database build context. No Cloudflare
account or hosted Hyperdrive resource is needed. The all-zero configuration ID
is a local placeholder. Wrangler runs on your host; the database container
publishes only `127.0.0.1:13306`.

`check:local` and `dev:local` supply the matching local connection string.
The fixed credentials in Compose and `local.mjs` are disposable demo values.
To use another port, supply the same environment variable to both commands:

```sh
DB_PORT=13307 npm run db:up
DB_PORT=13307 npm run dev:local
```

Stop the database with `npm run db:down`; its volume preserves data. To delete
this example's database volume and reseed it, run `npm run db:reset`. Stop the
Worker first. Schema initialization runs only on a fresh volume. Use distinct
Compose project names (`COMPOSE_PROJECT_NAME`) when running multiple copies.

## What to expect

The default `app/app.psp` renders a read-only inventory table with WebDyne,
including a seeded Club dinner item. Results are limited to 100 rows and HTML
values are escaped. `app/app.pagi` returns the same rows as JSON.

To run the native PAGI supplement, stop the Worker and run:

```sh
npm pkg set webdyne.entry=app.pagi
npm run dev:local
```

Switch back with `npm pkg set webdyne.entry=app.psp` and restart.

## Using your own database

Use ordinary `npm run check` / `npm run dev` with your private
`CLOUDFLARE_HYPERDRIVE_LOCAL_CONNECTION_STRING_DB` instead of the local helpers.
For deployment, replace the all-zero Hyperdrive ID with your hosted configuration.
Local database connections bypass Hyperdrive pooling/caching; use a cache-disabled
binding for remote read-after-write checks. Never deploy these demo credentials.

See the [Hyperdrive API](../../lib/WebDyne/Cloudflare/Hyperdrive.pm.md) for
bound parameters, transactions, exact types, deadlines and dialect restrictions.
