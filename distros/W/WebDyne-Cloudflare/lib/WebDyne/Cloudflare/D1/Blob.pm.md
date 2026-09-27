# WebDyne::Cloudflare::D1::Blob

Explicit binary wrapper created by `WebDyne::Cloudflare::D1->blob($bytes)`
or `new($bytes)`. Accepts defined scalar byte strings, including empty strings
and NUL bytes. Wide characters above 255 are rejected immediately; encode
Unicode text explicitly before using a binary wrapper.

`wire_value()` returns the private base64 envelope used by the host bridge.
`bytes()` returns the original bytes.
It performs no asynchronous work or storage operation.
