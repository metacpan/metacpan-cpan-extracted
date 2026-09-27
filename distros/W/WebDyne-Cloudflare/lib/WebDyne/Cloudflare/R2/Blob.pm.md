# WebDyne::Cloudflare::R2::Blob

Explicit binary wrapper created by `WebDyne::Cloudflare::R2->blob($bytes)`
or `new($bytes)`. Accepts defined scalar byte strings, including empty strings
and NUL bytes. Wide characters above 255 are rejected immediately; encode
Unicode text explicitly before using a binary wrapper.

`wire_value()` returns the private base64 envelope used by the host bridge.
It performs no asynchronous work or storage operation.
