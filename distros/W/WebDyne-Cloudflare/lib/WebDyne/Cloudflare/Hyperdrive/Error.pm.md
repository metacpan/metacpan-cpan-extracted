# WebDyne::Cloudflare::Hyperdrive::Error

Structured host failure with string overload and `name()`, `code()`, `message()`, `details()` and `outcome_unknown()` accessors. PostgreSQL errors retain SQLSTATE and selected diagnostic fields. An interrupted COMMIT can have an unknown outcome; applications must not retry it automatically. Database details may contain submitted data and belong in private diagnostics.

`cleanup_errors()` returns secondary rollback/close failures as an array reference.
A failed rollback preserves an original Hyperdrive Error object and its SQLSTATE.
Other callback exceptions are wrapped only when cleanup also fails; `cause()` then
returns the original exception and `message()` describes it. Successful rollback
rethrows the original callback exception unchanged. Error details are intended for
private handling; they are not safe automatic HTTP response bodies.

For MySQL, `code()` returns the symbolic server code, `sqlstate()` returns the
five-character SQLSTATE and `errno()` returns the numeric error. Connection and
authentication failures are redacted. PostgreSQL retains its existing SQLSTATE in
`code()`; its new MySQL-specific accessors return undef.
