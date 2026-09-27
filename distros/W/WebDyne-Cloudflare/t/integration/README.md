# Authenticated Hyperdrive qualification

These maintained test harnesses use the production extension and generated Worker.
They are not user examples. The PostgreSQL harness includes the reusable public-API
fixture as `core.pagi`; both drivers share `support/auth.js`.

Use released runtime and extension packages and a disposable database.
PostgreSQL requires `t/fixtures/hyperdrive-postgres.sql`; MySQL uses unique test
tables and removes them. Disable Hyperdrive query caching. Supply your own
32-hex-digit Hyperdrive ID explicitly:

```sh
node t/integration/hyperdrive-postgres/stage.mjs 1.0.14 1.7.1 NEW_DIRECTORY HYPERDRIVE_ID
# Or use t/integration/hyperdrive-mysql/stage.mjs with a MySQL binding.
```

In the new directory:

```sh
npm install --ignore-scripts
npm run check
node --input-type=module <<'JS'
import {readFile,writeFile} from 'node:fs/promises';
const config=JSON.parse(await readFile('.webdyne/wrangler.jsonc','utf8'));
config.main='worker.js';
config.preview_urls=false;
config.$schema='node_modules/wrangler/config-schema.json';
await writeFile('wrangler-auth.jsonc',JSON.stringify(config,null,2));
JS
npx --no-install wrangler deploy --dry-run --config wrangler-auth.jsonc
npx --no-install wrangler deploy --config wrangler-auth.jsonc --secrets-file .deployment-secrets.json
```

The generated secret file is mode 0600. Every route requires its bearer token and
expires after one hour. Deploy only the authenticated wrapper, never the bare
fixture application. From the source checkout, run the matching driver:

```sh
node t/integration/hyperdrive-postgres/smoke.mjs WORKER_URL SECRET_FILE RESULT_FILE
```

Use an output path outside source control. Results contain run tokens needed for
scoped recovery if a test is interrupted. PostgreSQL checks types, SQL, CRUD,
transactions, limits, backend termination, recovery and SSE client cancellation.
Independent connections verify writes and rollback. The verifier waits longer than
the deliberate origin sleep; cancellation is not proof of immediate origin stop.
MySQL checks CRUD, exact types, transaction failure, limits and concurrent recovery.

After testing, verify scoped database cleanup, delete the exact temporary Worker
with `wrangler delete NAME --config wrangler-auth.jsonc`, confirm it is absent,
and remove the secret file. Do not reset the database or change its permissions.
Historical evidence is summarized in [qualification](../../docs/qualification.md).

Local connections can exercise SQL and recovery, but the full PostgreSQL smoke
suite includes a remote disconnect assertion. With Wrangler 4.131.1 and runtime
1.0.14 the local proxy did not mark the request signal aborted; that case failed
locally even though rollback/cleanup completed. Do not weaken the remote assertion
or claim a complete live qualification from local development. See the dated record.
