# Examples

Each directory is an independent application. WebDyne PSP is the default; native
PAGI supplements demonstrate explicit HTTP responses without page rendering.

| Directory | Default WebDyne page | Native PAGI supplement |
| --- | --- | --- |
| [storage](storage/README.md) | D1 query/JSON API, KV and R2 greeting forms | Not needed for these page examples |
| [hyperdrive](hyperdrive/README.md) | PostgreSQL inventory table | Read-only JSON inventory |
| [hyperdrive-mysql](hyperdrive-mysql/README.md) | MySQL inventory table | Read-only JSON inventory |
| [d1-sessions](d1-sessions/README.md) | Bookmark continuation form | HTTP bookmark/metadata endpoint |
| [secrets-store](secrets-store/README.md) | Non-secret retrieval confirmation | Fixed text response |
| [durable-objects](durable-objects/README.md) | Persistent counter form | JSON GET/POST client |

## Install and run

Copy one directory outside this checkout. For example:

```sh
cp -R examples/d1-sessions /tmp/webdyne-d1-sessions-example
cd /tmp/webdyne-d1-sessions-example
npm install
npm run check
npm run dev
```

The examples require ZeroPerl 1.0.14+ and WebDyne::Cloudflare 1.7.1+.
`npm install` installs the released packages from npm.

`npm run check` generates the Worker and its Wrangler configuration, then performs
a dry run. `npm run build` generates only the Worker artifacts. Service READMEs
list any database schema or local secret setup required before requests work. The
default URL is printed by the development command.

## Local service setup

Every example README contains its complete quick start. PostgreSQL and MySQL
include a pinned `compose.yaml` that seeds a local database and publishes only a
loopback port. Use `npm run db:up`, `npm run check:local`, and `npm run dev:local`.
`db:down` preserves database data; `db:reset` deletes and reseeds that example's
volume. The local helpers deliberately use demo credentials and a loopback URL.

For Secrets Store, run `npm run check` to generate the Wrangler configuration,
then `npm run setup:local` to create a fixed dummy secret with remote access
explicitly disabled. D1/KV/R2 and Durable Objects use Wrangler's local
implementations; they need no Docker services.

## Native PAGI alternatives

For a directory with `app/app.pagi`, stop the Worker, change its entry, and restart:

```sh
npm pkg set webdyne.entry=app.pagi
npm run check
npm run dev
```

Switch back with `npm pkg set webdyne.entry=app.psp`. Both variants use the same
bindings and schema; they are alternate applications, not simultaneous routes.
Durable Object handlers remain ordinary Perl modules in both variants.

## Local and remote resources

Storage IDs in examples are local placeholders. The Hyperdrive examples include Docker Compose databases and local connection
helpers; no hosted configuration is required for their local quick starts. Configure real resources
explicitly before deployment. The examples are small local demonstrations:
add application authentication and request authorization before exposing writes
publicly. No example prints database credentials or secret values.

Regression fixtures and authenticated database qualification live under `t/` and
`t/integration/`; see [TEST.md](../TEST.md). Build outputs, dependencies and local
Wrangler state are ignored and are not example source.
