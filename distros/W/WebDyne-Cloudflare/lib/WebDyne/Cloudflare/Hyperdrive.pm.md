# WebDyne::Cloudflare::Hyperdrive

Asynchronous PostgreSQL and MySQL queries through a request's Cloudflare Hyperdrive binding.
This API borrows DBI conventions; it is not a DBI driver and does not require DBI,
Moose or an ORM. It requires the Hyperdrive-enabled JavaScript extension and a
ZeroPerl runtime with awaited cleanup support.

```perl
use Future::AsyncAwait;
use WebDyne::Cloudflare::Hyperdrive;

my $db_or=WebDyne::Cloudflare::Hyperdrive->new(scope => $scope_hr, binding => 'DB');
my $customer_hr=await $db_or->selectrow_hashref(
    'SELECT id, name FROM customers WHERE id=$1', undef, $customer_id);

my $order_id=await $db_or->transaction(async sub {
    my ($tx_or)=@_;
    my $row_ar=await $tx_or->selectrow_arrayref(
        'INSERT INTO orders (customer_id) VALUES ($1) RETURNING id', undef, $customer_id);
    await $tx_or->do('INSERT INTO order_items (order_id, sku) VALUES ($1, $2)',
        undef, $row_ar->[0], $sku);
    return $row_ar->[0];
});
await $db_or->disconnect();
```

## Construction and queries

`new(scope => $scope_hr, binding => 'DB')` validates the request capability without
opening a network connection. Binding defaults to DB. Other constructor options
are rejected. Each object owns an independent lazy logical connection.

`selectrow_arrayref($sql, $attr_hr, @bind)` and
`selectrow_hashref($sql, $attr_hr, @bind)` return Futures resolving to the first row
or undef. `selectall_arrayref($sql, $attr_hr, @bind)` returns a Future resolving to
all array rows, or hash rows with `{ Slice => {} }`. No rows gives an empty array.
Hash rows use the last column when names repeat; use SQL aliases for joins.

`do($sql, $attr_hr, @bind)` returns a Future resolving to affected-row count,
`0E0` for a known zero (true as a boolean), or -1 for an unknown count. Use a
select method for INSERT/UPDATE/DELETE RETURNING when the returned rows are needed.

Use undef or an empty hash for absent attributes. Slice is accepted only by
selectall_arrayref; unknown attributes are errors. The attribute position is never
treated as a bind value. Use PostgreSQL `$1`, `$2` placeholders or MySQL `?`
placeholders and bind values separately. SQL dialects are not translated and no
automatic LIMIT is added. Values cannot stand in for identifiers. Multiple SQL statements
and direct transaction/session-control commands are unsupported.

`prepare($sql, $attr_hr)` constructs a local
[Statement](Hyperdrive/Statement.pm.md) synchronously. It does not issue SQL PREPARE.
Statement execution buffers bounded results; its fetch methods are synchronous.

`blob($bytes)` constructs an explicit binary parameter wrapper. Normal scalars
are text parameters; use SQL casts to disambiguate inferred PostgreSQL types.
Pass undef for SQL NULL and JSON::PP booleans for booleans. Encode JSON documents
as text explicitly. Arbitrary references and text containing NUL are rejected.

## Transactions and lifetime

`begin_work()`, `commit()` and `rollback()` return Futures resolving to 1.
Await each operation. Nested transactions are unsupported. Errors within a
transaction require rollback before continuing.

`transaction($callback_cr)` returns a Future, passes a transaction-scoped database
facade to the callback, awaits its Future, commits on success, and returns its
scalar result (including false or undef). On callback failure it rolls back and
rethrows the original exception. If rollback also fails, a Hyperdrive Error retains
the primary error and secondary cleanup failure. A lost commit response can have
an unknown outcome; it is never retried or described as a successful rollback.

Await earlier operations before entering a callback transaction, and await every
operation started by the callback. Unfinished callback operations are an error.
While the callback owns the connection, parent database/statement calls are blocked.
Use only its facade. Explicit transaction controls and disconnect are unavailable
on that facade. It and its statements expire when the callback ends.

The host serializes SQL operations on each connection. Overlapping execution of
one statement is rejected. Separate database objects can operate independently
within the configured request connection limit. This does not promise concurrent
Perl WASM execution: the runtime schedules its interpreter.

`disconnect()` returns an idempotent Future resolving to 1; it rolls back unfinished
work and invalidates the database and its statements immediately. Unused objects
disconnect without opening a connection. Await it when convenient; request teardown
also owns rollback/close. Never rely on a Perl destructor for asynchronous cleanup.

Cancelling an operation's Future invalidates the database handle. Disconnect it;
otherwise bounded request teardown performs cleanup. Cancellation is not proof
that the database stopped executing or that a write did not happen. Failed managed
cleanup or an ambiguous commit similarly requires disconnecting the handle.

## Values, errors and limits

With PostgreSQL, SQL NULL becomes undef; booleans become JSON::PP booleans. Small integers and
finite floats become numbers. BIGINT and NUMERIC remain exact text, dates/times
retain PostgreSQL text and microseconds, bytea becomes bytes, JSON/JSONB remains
JSON text, and arrays/other types remain PostgreSQL text. JSON `null` therefore
differs from SQL NULL. Non-finite floats are the strings NaN, Infinity or -Infinity.
Timestamps retain the server's output timezone representation; no session timezone
is changed. Column OIDs are available through Statement metadata.

Host failures throw [Error](Hyperdrive/Error.pm.md) objects with SQLSTATE where
available. Local argument/lifetime errors throw descriptive exceptions. Synchronous
methods can throw immediately; valid I/O calls return Futures. Database diagnostics
can contain submitted values and should not be copied into public HTTP responses.

Worker defaults: four logical connections per request, 1 MiB request, 4 MiB result,
10,000 rows, 5 s connect, 10 s query and 5 s cleanup. Configure overrides in the
JavaScript extension, not Perl query attributes. Results are not silently truncated.
The driver can allocate a large individual field before applying the result bound;
this is not an absolute process memory ceiling or a streaming cursor API.

A deadline closes the client connection; it does not confirm cancellation at the
origin database. The origin may continue running the statement while Hyperdrive
settles its pooled connection. Subsequent work can wait for that pool and hit its
own deadline. Do not immediately retry writes after a timeout: their outcome can
be unknown. Configure database-side statement limits separately when required.

## MySQL and compatible databases

The JavaScript entry point selects PostgreSQL (`postgres:` or `postgresql:`) or
MySQL (`mysql:`) from each Hyperdrive binding's connection string. Keep the same
Perl constructor and `hyperdriveBindings` configuration. No `driver` argument or
new ZeroPerl runtime is required; PostgreSQL and MySQL bindings can coexist.
Credentials stay in JavaScript. The tested MySQL driver is pinned mysql2 3.24.4.

```perl
my $statement_or=$db_or->prepare('INSERT INTO customers (name) VALUES (?)');
await $statement_or->execute($name);
my $id=$statement_or->insert_id();  # Exact decimal string, including large IDs.
my $customer_hr=await $db_or->selectrow_hashref(
    'SELECT id, name FROM customers WHERE id=?', undef, $id);
```

MySQL executes a single text-protocol query. `prepare()` remains local; it does
not use server-side prepared statements. The adapter substitutes only unquoted
`?` placeholders outside comments, using UTF-8 hex expressions for text and hex
literals for blobs. This avoids dependence on backslash escaping or SQL mode.
It rejects mismatched parameter counts, `??` identifier placeholders, executable
MySQL/MariaDB comments and quoted SQL literals containing backslashes. Bind those
strings instead. LIMIT/OFFSET placeholders accept validated unsigned decimal
integers (including zero). Ordinary quoted strings and comments may contain literal `?`.

Supported statement families are SELECT, INSERT, UPDATE, DELETE, REPLACE, WITH,
EXPLAIN, SHOW, DESCRIBE/DESC and ordinary CREATE/ALTER/DROP/TRUNCATE/RENAME/
ANALYZE/OPTIMIZE/CHECK statements. The latter group is rejected inside transactions
because MySQL can commit implicitly. USE, SET, locks, XA, CALL, LOAD DATA, SQL
PREPARE/EXECUTE, multiple statements and multiple result sets are unsupported.
Use transactional tables (InnoDB) for rollback guarantees; table engines, triggers,
and server/provider restrictions remain the application's responsibility.

MySQL BIGINT and DECIMAL values, JSON documents and dates/times remain strings;
DATETIME(6) retains microseconds. Small integers and finite floating values become
numbers. TINYINT(1)/BOOLEAN is numeric 0/1, not a PostgreSQL boolean. Binary fields
return bytes. SQL NULL remains undef and JSON null remains text `null`. MySQL
column metadata uses `driver => 'mysql'`, `type`, `flags` and `charset`; it does
not invent PostgreSQL OIDs. Array rows retain duplicate columns.

`rows()` and `execute()` use mysql2's affectedRows for DML. With the default
FOUND_ROWS flag an UPDATE counts matched rows, including unchanged values.
MySQL statement accessors `insert_id()`, `affected_rows()` and `warning_count()`
expose DML metadata; SELECT and PostgreSQL results return undef for these fields.
MySQL `code()` is symbolic (for example ER_DUP_ENTRY), while `sqlstate()` and
`errno()` expose the server's SQLSTATE and numeric error. As with PostgreSQL,
a SQL error inside a transaction requires rollback before further work.

Qualified with Aiven MySQL 8.4.8 through Hyperdrive and Perl/WASM, plus direct
adapter tests against MySQL 8.4.11 and MariaDB 11.8.9. PlanetScale/Vitess has not
been qualified here; compatible protocol support does not establish identical
SQL, DDL, or transaction behavior for every provider.
