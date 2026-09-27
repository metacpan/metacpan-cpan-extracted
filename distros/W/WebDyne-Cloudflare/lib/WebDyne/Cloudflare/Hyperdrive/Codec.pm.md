# WebDyne::Cloudflare::Hyperdrive::Codec

Internal protocol v1 value conversion used by the Hyperdrive facade. `parameters(@values)` encodes undef, booleans, scalar text and explicit Blob objects. `result($result_hr)` preserves ordered column metadata and decodes row arrays. Big integers, numeric values, JSON, arrays and date/time values remain text. SQL NULL becomes undef; JSON null remains the string `null`. Bytea returns bytes. Non-finite floats remain explicit strings. Hash/object parameters are rejected; JSON callers must encode their documents explicitly.

MySQL metadata uses a driver name and native numeric type code instead of `oid`.
BIGINT, DECIMAL, JSON and temporal values remain text, binary fields become byte
strings, and TINYINT(1) remains numeric. Existing PostgreSQL envelopes are unchanged.
