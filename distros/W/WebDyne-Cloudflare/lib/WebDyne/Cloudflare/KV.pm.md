# WebDyne::Cloudflare::KV

Future-returning Workers KV facade. Construct with
`new(scope => $scope_hr, binding => 'CACHE')`; the default binding is `KV`.
`binding()` returns its name.

## Interface

- `get($key, type => 'text', cache_ttl => $seconds)`.
- `get_with_metadata($key, %options)` returns a hash with value, metadata and
  optional cache_status.
- `put($key, $value, %options)` accepts expiration, expiration_ttl and metadata.
- `put_json($key, $value_ref, %options)` JSON-encodes before writing.
- `delete($key)`.
- `list(prefix => $prefix, cursor => $cursor, limit => $limit)`.

All operations return Futures. Read types are text, json and bytes.
`blob($bytes)` accepts function, class or object invocation and one byte payload.
Missing values return undef. KV is eventually consistent; reads may be stale.

The JavaScript adapter enforces kvMaxValueBytes (16 MiB by default) on writes
and returned values. Provider reads are buffered before this check; this is a
bridge payload limit, not a streaming-memory guarantee.
Errors fail with [KV::Error](KV/Error.pm.md). Invalid capabilities throw at
construction. Internal validation and host-call helpers are not supported API.

Text inputs, including nested metadata keys and values, are normalized from
unflagged UTF-8 without changing caller data. Invalid UTF-8, cyclic containers
and duplicate normalized keys are rejected before calling the host. See
[the usage guide](../../../README.md#text-binary-data-and-errors).
