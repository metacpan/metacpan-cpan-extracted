# WebDyne::Cloudflare::D1::Session

Future-returning D1 session facade, created with
[`with_session()`](../D1.pm.md#sessions-and-read-replication).

```perl
my $session_or=await $db_or->with_session('first-primary');
my $row_hr=await $session_or->first('SELECT name FROM things WHERE id = ?1', $id);
my $bookmark=await $session_or->get_bookmark();
```

## Interface

- `get_bookmark()` returns a Future of the provider's latest opaque bookmark
  string, or `undef` when the provider returns null.
- `binding()`, `prepare()`, `run()`, `all()`, `first()`, `batch()` and `blob()`
  have the same interface and result shapes as the D1 facade. Prepared
  statements also support `raw()`.
- Create sessions through the database's `with_session()` method. Direct
  construction and nested `with_session()` calls are rejected.

Statements retain their owning session. A batch accepts statements from that
exact session object only, including after `bind()`. Database and other-session
statements are rejected before crossing the host boundary.

Await dependent operations in order. A session provides sequential consistency,
not an interactive transaction or a snapshot isolated from other clients.
Use `batch()` when a fixed sequence must execute atomically.

The host retains the native session for the lifetime of its request capability.
It cannot be reused with another binding or request, and expires on request
release. Keep only its bookmark across requests, not this object. Bookmarks
are opaque; do not parse, compare, or combine them. Application code controls
bookmark transport and keeps bookmarks separate for each database.

Host failures fail the Future with `WebDyne::Cloudflare::D1::Error`. Sessions
never fall back silently to ordinary primary queries. No implicit retries,
SQL routing logic, or bookmark headers are added by this facade.
