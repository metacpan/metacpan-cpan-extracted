# WebDyne::Cloudflare::SecretsStore

Read an account-level Cloudflare Secrets Store secret through a Worker binding.
Each binding selects one secret. The lightweight object follows the existing
request-scoped capability bridge; it is not a store-wide lookup interface or
an interface to ordinary Worker string secrets.

## Synopsis

```perl
use Future::AsyncAwait;
use WebDyne::Cloudflare::SecretsStore;

# Inside an async WebDyne handler:
my $secret_or=WebDyne::Cloudflare::SecretsStore->new(
    scope   => $self->r()->{'scope'},
    binding => 'API_KEY',
);
my $api_key=await $secret_or->get();
# Use the value for the intended authenticated operation; do not render it.
```

## Methods

`new(scope => $scope_hr, binding => 'API_KEY')` validates the request capability
and binding allowlist. The default binding is `SECRET`. Binding names follow
the existing uppercase identifier convention. Invalid construction throws.

`binding()` returns the configured binding name.

`get()` takes no arguments and returns a Future resolving to the secret string.
Empty strings, `0`, Unicode and newlines are preserved. It does not parse JSON.
Use `await` in asynchronous handlers. In existing synchronous handlers using
ZeroPerl's suspending host bridge, `get()->get()` follows the other service APIs.
Failures fail the Future with `WebDyne::Cloudflare::SecretsStore::Error`.

## Configuration

Merge these keys into the application's package.json:

```json
{
  "webdyne": {
    "extensions": {
      "@webdyne/webdyne-cloudflare": { "secretsStoreBindings": ["API_KEY"] }
    },
    "cloudflare": {
      "secretsStoreSecrets": [{
        "binding": "API_KEY",
        "storeId": "YOUR_32_HEX_STORE_ID",
        "secretName": "upstream-api-key"
      }]
    }
  }
}
```

Generated configuration requires ZeroPerl 1.0.12. With older runtimes, supply
your own Wrangler configuration containing `secrets_store_secrets` entries
with `binding`, `store_id`, and `secret_name`. Existing user-owned Wrangler files
are preserved. Named environments must each declare their secret bindings.
No additional compatibility flag is required for Secrets Store.

Custom Workers can pass `secretsStoreBindings` to
`createWebDyneCloudflareExtension`. If that option is omitted,
`WEBDYNE_SECRETS_STORE_BINDINGS` accepts a comma-separated allowlist.
An explicit empty array disables exposure even when the fallback is set.
The Hyperdrive provider accepts the same options.

## Lifecycle and secret handling

Reads happen only when `get()` is called; the adapter adds no value cache.
The PAGI scope contains only binding names and capability metadata, never values.
Cleanup revokes the capability, drops stored binding references and rejects
successful reads completing after revocation. It cannot cancel Cloudflare's
underlying read or erase copies already returned to application code.
Do not retain values or objects across requests, log values, or put them in
responses, source, deployment settings or exception messages.

Only `get` is supported. Provisioning, listing, rotation and deletion remain
management operations outside this API. Retrieval uses the native binding,
without a Cloudflare management token in Perl.

## Errors

See [SecretsStore::Error](SecretsStore/Error.pm.md). Error names distinguish
host, protocol, capability, binding and retrieval failures. Messages are fixed;
raw provider messages, causes, codes and malformed response bodies are discarded.
A missing or inaccessible secret fails retrieval, rather than returning undef.

## Development

Use local dummy secrets created with Wrangler's `secrets-store secret create`
command without `--remote`. Local development cannot read production secrets.
Provision a production secret with the `workers` scope and bind it before
production use. See the [example](../../../examples/secrets-store/README.md)
and [Cloudflare's Workers integration documentation](https://developers.cloudflare.com/secrets-store/integrations/workers/).
