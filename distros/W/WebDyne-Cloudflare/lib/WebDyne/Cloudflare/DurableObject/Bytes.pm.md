# WebDyne::Cloudflare::DurableObject::Bytes

Explicit binary value for Durable Object RPC and SQLite BLOB parameters/results.
`new($bytes)` accepts one defined byte string, at most 1 MiB; wide characters are
rejected. `value()` returns the original byte string. Prefer the public
`WebDyne::Cloudflare::DurableObject::bytes($bytes)` helper. Complete encoded message
limits may be reached before the raw byte limit because the bridge uses base64.
