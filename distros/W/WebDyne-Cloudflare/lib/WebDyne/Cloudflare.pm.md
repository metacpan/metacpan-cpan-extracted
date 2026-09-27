# WebDyne::Cloudflare

Cloudflare service capabilities for WebDyne::PAGI. This npm-first distribution
ships Perl facades and JavaScript host adapters together. It requires Perl 5.20
or later and Future::AsyncAwait; WASM verification currently uses Perl 5.44.

See [D1](Cloudflare/D1.pm.md), [KV](Cloudflare/KV.pm.md),
[R2](Cloudflare/R2.pm.md), [Hyperdrive](Cloudflare/Hyperdrive.pm.md), and
[Secrets Store](Cloudflare/SecretsStore.pm.md), and
[Durable Objects](Cloudflare/DurableObject.pm.md).
Cloudflare binding objects stay in JavaScript.
Each Perl facade carries only a request-scoped capability and binding name.
Never retain a facade beyond the request which created it.

Text inputs, including nested metadata keys and values, are normalized from
unflagged UTF-8 without changing caller data. Invalid UTF-8, cyclic containers
and duplicate normalized keys are rejected before calling the host. See
[the usage guide](../../README.md#text-binary-data-and-errors).
