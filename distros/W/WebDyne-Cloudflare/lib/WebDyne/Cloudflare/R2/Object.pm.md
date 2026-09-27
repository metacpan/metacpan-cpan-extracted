# WebDyne::Cloudflare::R2::Object

Buffered R2 result wrapper. Usually returned by R2 get, head, put or list.
`new($metadata_hr)` shallow-copies a metadata hash. `as_hash()` returns a
shallow hash copy; nested metadata references remain shared.

Accessors: key, version, size, etag, http_etag, uploaded, http_metadata,
custom_metadata, storage_class, range and body. Each is called with parentheses.
The body contains bytes only for a get result. A head/put/list result has no
body. These accessors are synchronous; they perform no host calls.
