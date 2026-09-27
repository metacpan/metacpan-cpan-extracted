# Testing WebDyne::Cloudflare

Use Node.js 24+, Perl 5.20+ with Future and Future::AsyncAwait, and the locked
Wrangler version. Worker tests need the released ZeroPerl 1.0.14+
Perl 5.44 runtime. The declared minimum Perl has not been separately
qualified; see the [qualification record](docs/qualification.md).

## Contract and package checks

```sh
npm ci --ignore-scripts
perl Makefile.PL
make test
make distcheck
npm run pack:check
npm audit --omit=dev
```

`npm test` runs both `prove -Ilib t` and `node --test t.js/*.test.mjs`.
Tests cover D1 (including sessions/batches), KV, R2, Hyperdrive PostgreSQL/MySQL,
Secrets Store, Durable Objects, request cleanup, errors, package contents and
staging workflow contracts. The shared integration authentication test is included
in this default suite. Workflow tests mock publication; they do not upload or
approve a package. Use `actionlint .github/workflows/*.yml` for workflow changes.

## Local Worker storage integration


Create an independent test application using released runtime and extension
packages. The destination must not already exist:

```sh
node t.js/prepare-storage-smoke.mjs \
  --runtime-version 1.0.14 \
  --extension-version 1.7.1 \
  --destination /tmp/webdyne-cloudflare-smoke
cd /tmp/webdyne-cloudflare-smoke
npm install --ignore-scripts
npm run build
npm run check
npx wrangler d1 execute DB --local --config .webdyne/wrangler.jsonc --file schema.sql
npm run dev -- --port 8790
```

Use the generated Wrangler configuration path reported by the runtime if its
build layout differs. From this repository, run:

```sh
npm run smoke:d1 -- http://127.0.0.1:8790/
npm run smoke:kv -- http://127.0.0.1:8790/
npm run smoke:r2 -- http://127.0.0.1:8790/
```

`--services d1`, `kv`, `r2`, or a comma-separated subset narrows staging.
Smoke applications use only `t/fixtures/app` and `t/fixtures/schema.sql`.
The user-facing pages in `examples/storage/app` are independent of smoke tests.

D1 checks parameterized writes, JSON routes, failure/recovery, 24 concurrent
reads and eight isolated batch sequences. Each batch checks ordered writes
and reads, rollback on a middle constraint failure, and subsequent recovery.
KV/R2 check storage operations and cleanup; cleanup failure fails the smoke.

Remote execution requires deliberately configured test resources and the
corresponding `--remote true`, `--d1-database-id`, `--kv-namespace-id` or
`--r2-bucket-name` staging options. Test endpoints expose fixture mutations;
use them only in isolated test environments.

## Example validation

```sh
node t.js/qualify-examples.mjs 1.0.14 --compose
```

The runner copies each example, installs the released runtime and packages the current extension for testing, checks both entry
builds, starts the actual npm development commands and validates HTTP forms/JSON.
With `--compose`, Docker starts the supplied PostgreSQL/MySQL services on local
ports 35432/33316 under unique project names and adds an HTML-escaping probe row.
It tests repeated local dummy-secret setup. Generated applications and test
database volumes are removed on completion. Optional example names limit the run.
Without `--compose`, PostgreSQL/MySQL HTTP checks require private `WEBDYNE_POSTGRES_TEST_URL` / `WEBDYNE_MYSQL_TEST_URL`
variables pointing to disposable local databases. Without those URLs, it reports those
HTTP checks as skipped and still builds both entries. Seed each database using
its example schema, plus this HTML-escaping probe row:

```sql
INSERT INTO demo_inventory VALUES ('ESCAPE', '<script>alert(1)</script>', 1);
```


Follow [examples/README.md](examples/README.md) to copy each independent app
and install the released packages from npm. Run `npm run check` for the generated Worker
and Wrangler dry run. Lint PSP pages with `wdlint`, then render actual GET/POST
requests under the Worker to exercise bindings and verify HTML escaping.
Native `wdrender` needs an injected request scope/host adapter for service pages;
a bare native render cannot access Cloudflare bindings.

Check storage reads and submitted greetings, inventory rows, D1 bookmark
continuation, the secret retrieval confirmation, and counter reads/increments.
Run native PAGI supplements by setting `webdyne.entry=app.pagi`, rebuilding and
restarting the Worker. Validate JSON, response headers and concurrent requests.
Database examples need a configured PostgreSQL/MySQL server; a bundle dry run
alone does not prove database connectivity.

The native Secrets Store response has a dedicated smoke check:

```sh
npm run smoke:secrets-store -- http://127.0.0.1:8793/
```

Use a local dummy secret only. The script checks four concurrent fixed responses
and `Cache-Control: no-store`. For the default PSP page, check the HTML contains
`Secret retrieval succeeded` and never includes the dummy secret.

D1 session checks send the returned `x-d1-bookmark` on a later request. Local
D1 cannot prove replica routing or lag; remote testing needs a replication-enabled
test database. Ordinary calls and session metadata can legitimately use the primary.

## Durable Objects

```sh
node t.js/qualify-durable-objects.mjs 1.0.14
```

This independent fixture packs the current extension, builds and dry-runs a
Worker, and exercises local workerd/Perl RPC, concurrent updates, object isolation,
initialization, atomic rollback, stale handles, call cycles, serialization,
errors, and SQLite persistence across restart. It deletes its temporary project.
The user-facing counter example is verified separately.

## Hyperdrive integration

Maintained generated-app harnesses live in
[t/integration](t/integration/README.md). PostgreSQL includes the public API,
transaction/type fixture and failure/SSE cancellation cases. MySQL includes
CRUD, exact types, transactions, failure/limit checks and recovery. The wrappers
require expiring authentication and independently verify database results and
cleanup. Stage with an explicitly supplied Hyperdrive ID; no account identifier
is built into the harness.

`t/fixtures/hyperdrive-postgres.sql` creates an isolated schema with immutable
seed data and a `transaction_probe` table. Apply it as the test database owner
using `psql` with `-v ON_ERROR_STOP=1`. It is transactional and repeatable but does
not reset altered data or repair an incompatible schema. Each test uses a UUID
and deletes only its own rows. Disable Hyperdrive caching for correctness checks.

For a disposable local MySQL/MariaDB administrative test server:

```sh
node t.js/integration-mysql.mjs
```

Set `WEBDYNE_MYSQL_TEST_URL` privately. This opt-in script creates/drops a unique
table and temporarily changes/restores global SQL mode; use an isolated server.
No live database or remote Worker test is implied by passing the default suite.

Historical results and remaining limits are in
[docs/qualification.md](docs/qualification.md). Package/release identity is
recorded by the [release workflow](docs/releasing.md), not by committed transient
result dumps.
