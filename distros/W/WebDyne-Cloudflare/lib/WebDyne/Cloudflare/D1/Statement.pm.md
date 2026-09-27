# WebDyne::Cloudflare::D1::Statement

Create statements through `$db_or->prepare($sql)`. `bind(@params)` returns a
new statement without modifying the original.
Pass these statements to `$db_or->batch([$statement_or, ...])` for atomic
execution. Every statement must originate from that exact database object.

- `run()` and `all()` return a Future containing the D1 result hash
  (results, meta, success).
- `first()` returns a Future of a row hash or undef; `first($column)` returns a column
  value, including decoded BLOB bytes.
- `raw(column_names => 1)` returns a Future of arrays of column values, with an optional
  header row.

Statements retain their originating database capability and must not outlive
its request. Failures use WebDyne::Cloudflare::D1::Error.

Statements prepared by a [D1 session](Session.pm.md) retain that session through
`bind()` and execution. Session batches require the exact same owning session
object, just as ordinary batches require the same database object.
