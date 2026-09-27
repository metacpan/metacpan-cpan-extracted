# WebDyne::Cloudflare::Hyperdrive::Blob

Explicit binary input wrapper for PostgreSQL `bytea` and MySQL binary parameters. Construct with a Perl byte string; wide characters are rejected. `bytes()` returns the original bytes. The internal codec uses hexadecimal envelopes; ordinary scalars are always text parameters.
