# Configuration


There are two parts: enable the extension and allow the binding names Perl may
use, then tell Wrangler which resources those names refer to. Merge this
`webdyne` object into your existing package.json:

```json
{
  "webdyne": {
    "extensions": {
      "@webdyne/webdyne-cloudflare": {
        "d1Bindings": ["DB"],
        "kvBindings": ["CACHE"],
        "r2Bindings": ["ASSETS"]
      }
    },
    "cloudflare": {
      "d1Databases": [{
        "binding": "DB",
        "databaseName": "webdyne-time",
        "databaseId": "CLOUDFLARE-DATABASE-ID"
      }],
      "kvNamespaces": [{
        "binding": "CACHE",
        "namespaceId": "CLOUDFLARE-KV-NAMESPACE-ID"
      }],
      "r2Buckets": [{
        "binding": "ASSETS",
        "bucketName": "my-webdyne-assets"
      }]
    }
  }
}
```

Use only the arrays for services the application needs. The runtime's
`webdyne-cloudflare` command copies the extension's Perl modules to VFS
`/perl5/lib`, statically imports its Cloudflare adapter into the generated
Worker, and emits D1, KV, and R2 binding configuration for Wrangler. npm
installation itself runs no setup or deployment hooks.

### Hyperdrive / PostgreSQL

Enable Hyperdrive and map the binding to an existing configuration:

```json
{
  "webdyne": {
    "extensions": {
      "@webdyne/webdyne-cloudflare": { "hyperdriveBindings": ["DB"] }
    },
    "cloudflare": {
      "hyperdrive": [{ "binding": "DB", "id": "YOUR_32_HEX_HYPERDRIVE_ID" }]
    }
  }
}
```

Use extension 1.3.0 and runtime 1.0.11 or later, then run `webdyne-cloudflare check`
or `deploy`. No custom extension manifest or generated Worker edits are needed.
D1/KV/R2-only builds retain their original provider. User-owned Wrangler files
remain untouched; add the Hyperdrive binding and `nodejs_compat` yourself in that
case. Choose distinct binding names when combining services.

For local development, put the connection string in the private environment
variable `CLOUDFLARE_HYPERDRIVE_LOCAL_CONNECTION_STRING_DB`. Do not put credentials
in package.json. Use a caching-disabled Hyperdrive configuration when CRUD reads
must immediately reflect writes; Hyperdrive does not invalidate cached reads on
writes. See [Cloudflare local development](https://developers.cloudflare.com/hyperdrive/configuration/local-development/)
and [query caching](https://developers.cloudflare.com/hyperdrive/concepts/query-caching/).

```perl
my $db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr);
my $customer_hr=await $db_or->selectrow_hashref(
    'SELECT id, name FROM customers WHERE id=$1', undef, $customer_id);
await $db_or->disconnect();
```

The [API reference](../lib/WebDyne/Cloudflare/Hyperdrive.pm.md) covers transaction
callbacks, DBI-style attribute positions, exact types, deadlines and errors.
The [inventory example](../examples/hyperdrive) includes configuration and sample SQL.

### Extension options

Options live in `webdyne.extensions["@webdyne/webdyne-cloudflare"]`:

| Option | Default | Purpose |
| --- | --- | --- |
| `d1Bindings` | No bindings | Array of D1 names Perl may access, such as `["DB"]`. |
| `kvBindings` | No bindings | Array of KV names, such as `["CACHE"]`. |
| `r2Bindings` | No bindings | Array of R2 names, such as `["OBJECTS"]`. |
| `hyperdriveBindings` | No bindings | PostgreSQL/MySQL Hyperdrive binding names. |
| `secretsStoreBindings` | No bindings | Secrets Store binding names. |
| `durableObjectBindings` | No bindings | Durable Object namespaces; generated from object definitions by the CLI. |
| `durableObjectNativeBindings` | No bindings | Namespaces using native JavaScript RPC; also allow them in `durableObjectBindings`. |
| `hyperdriveLimits` | See API | Connection, row, byte, query and cleanup limits; see [Hyperdrive](../lib/WebDyne/Cloudflare/Hyperdrive.pm.md#values-errors-and-limits). |
| `kvMaxValueBytes` | `16777216` (16 MiB) | Maximum KV value payload handled by the bridge. |
| `r2MaxObjectBytes` | `16777216` (16 MiB) | Maximum buffered R2 body handled by the bridge. |

Binding names use uppercase letters, digits and underscores, starting with a
letter or underscore. Use positive integer byte limits. An explicit empty
binding array disables that service, including its compatibility-variable
fallback. These options expose existing bindings; they don't create resources.

### Resource definitions

These arrays live in `webdyne.cloudflare` and are translated by the runtime
CLI into **generated** Wrangler configuration:

| Array | Required fields | Optional fields | Wrangler destination |
| --- | --- | --- | --- |
| `d1Databases` | `binding`, `databaseName`, `databaseId` | `previewDatabaseId` | `d1_databases`: `binding`, `database_name`, `database_id`, `preview_database_id` |
| `kvNamespaces` | `binding` | `namespaceId`, `previewNamespaceId`, `remote` | `kv_namespaces`: `binding`, `id`, `preview_id`, `remote` |
| `r2Buckets` | `binding` | `bucketName`, `previewBucketName`, `jurisdiction`, `remote` | `r2_buckets`: `binding`, `bucket_name`, `preview_bucket_name`, `jurisdiction`, `remote` |

Supply the actual resource identifiers for deployment. KV/R2 allow omitted IDs
or names for local development with the bundled Wrangler. `remote: true`
selects real resources during development where supported; omit it for the
usual local storage workflow. Provisioning resources and creating a D1 schema
are separate from enabling the extension.

If you maintain a root `wrangler.jsonc` or select one with
`webdyne.cloudflare.wranglerConfig`, the runtime leaves it untouched. Put the
resource definitions in that file using Wrangler's names, while keeping the
extension allow-lists in package.json. For example, the equivalent binding
fragment is:

```json
{
  "d1_databases": [{
    "binding": "DB",
    "database_name": "webdyne-time",
    "database_id": "CLOUDFLARE-DATABASE-ID"
  }],
  "kv_namespaces": [{
    "binding": "CACHE",
    "id": "CLOUDFLARE-KV-NAMESPACE-ID"
  }],
  "r2_buckets": [{
    "binding": "ASSETS",
    "bucket_name": "my-webdyne-assets"
  }]
}
```

This is a fragment to merge into a working runtime configuration, not a whole
Worker config. Keep its entrypoint, module rules, runtime variables and
`enable_request_signal` flag. Rebuild after changing package options or Perl
modules. Once local checks pass, use `npm run login`, `npm run whoami` and
`npm run deploy` to deploy the configured application.

## Additional services

For MySQL, use the same Hyperdrive configuration with a `mysql:` connection
string and `?` SQL parameters. PostgreSQL uses `$1`, `$2`, and so on.
See the [MySQL restrictions](../lib/WebDyne/Cloudflare/Hyperdrive.pm.md#mysql-and-compatible-databases).

[Secrets Store](../lib/WebDyne/Cloudflare/SecretsStore.pm.md#configuration)
uses `secretsStoreBindings` and `cloudflare.secretsStoreSecrets` entries with
`binding`, `storeId`, and `secretName`. Generated configuration requires
ZeroPerl 1.0.12 or later.

[D1 sessions](../lib/WebDyne/Cloudflare/D1.pm.md#sessions-and-read-replication)
use the normal D1 binding. Enable read replication separately in the database;
carry session bookmarks between related requests. Ordinary queries retain
primary-only routing.

[Durable Objects](../lib/WebDyne/Cloudflare/DurableObject.pm.md#configuration)
use `cloudflare.durableObjects`, plus `perlLibrary` for application modules.
Perl-hosted objects require ZeroPerl 1.0.13 or later. The examples use the
qualified 1.0.14 runtime. Generated definitions select the correct namespace
allowlists; custom Workers must supply them explicitly.
