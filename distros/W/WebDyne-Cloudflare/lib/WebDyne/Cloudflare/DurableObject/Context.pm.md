# WebDyne::Cloudflare::DurableObject::Context

Invocation-scoped identity, bindings, and SQLite storage for a Perl-defined Durable
Object. The hosting adapter constructs the context; application packages receive
it as the first argument, without a package invocant or required base class.

```perl
package Example::Counter;
use Future::AsyncAwait;

async sub initialize {
    my ($context_or)=@_;
    await $context_or->storage()->batch([
        ['CREATE TABLE IF NOT EXISTS counter(id INTEGER PRIMARY KEY, value INTEGER)', undef],
        ['INSERT OR IGNORE INTO counter VALUES (1, 0)', undef],
    ]);
    return;
}

async sub increment {
    my ($context_or, $amount)=@_;
    return await $context_or->storage()->selectrow_hashref(
        'UPDATE counter SET value=value+? WHERE id=1 RETURNING value', undef, $amount,
    );
}
1;
```

`id()` returns this object's canonical ID. `scope()` returns the invocation scope,
which can construct other configured Cloudflare clients. `storage()` returns the
storage facade. All capabilities expire after the invocation and awaited cleanup.
Do not retain the context, its scope, storage facade, or derived clients for later
calls. Retain ordinary cached values only; SQLite is the durable source of truth.

## SQL methods

- `do($sql, undef, @bind)` resolves to Cloudflare's `rowsWritten` count. This can
  include index writes; it is not a DBI affected-row guarantee.
- `selectrow_hashref($sql, undef, @bind)` resolves to the first row hash or `undef`.
- `selectall_arrayref($sql, undef, @bind)` resolves to an array of row hashes.
- `query($sql, undef, @bind)` resolves to `{rows, rows_read, rows_written}`.
- `batch($statements_ar)` accepts an array of `[SQL, undef, @bind]` arrays and
  resolves to the corresponding array of query result hashes.

Methods return Futures and use `?` placeholders with separate bound parameters.
Only `undef` is accepted in the attributes position. These are DBI-inspired names,
not DBI compatibility. Parameters are strings, finite numbers, `undef`, or explicit
`DurableObject::Bytes`. SQL booleans should be bound as numeric 0/1. Duplicate column
names use the host cursor's row-object behavior; use distinct aliases.

Batches run inside one JavaScript `transactionSync` callback. A statement or result
encoding failure rolls back the entire batch. Every cursor is consumed before
returning to Perl. Limits are 100 statements per batch, 100 parameters per statement,
100000 UTF-8 bytes of SQL per statement, 10000 rows per result, and 1 MiB encoded
result/message size. Single queries also use a transaction so result-limit failures
roll back their writes. Cloudflare may impose additional platform limits.

Use one SQL statement per batch entry for clear parameter and result semantics.
The underlying `sql.exec` permits multiple SQL statements in one string, but binds
parameters and returns rows only for its last statement.

Separate awaited storage calls are not a rollback unit. Whole-invocation
serialization prevents another framework invocation from interleaving, but an
exception does not undo earlier successful calls. Use an atomic batch or a single
statement with `RETURNING` for atomic changes. Callback transactions and
`begin_work`/`commit`/`rollback` are not exposed. Each batch must be complete before
execution; it cannot use one statement's returned values to construct another.

## Initialization and errors

With `initialize: true`, the application package must define `initialize($context)`.
It may return a value or a Future. It runs before the first RPC invocation of each
interpreter, and must safely repeat after reconstruction. Use `IF NOT EXISTS`,
versioned application schema checks, and transactional batches as appropriate.
An initialization failure prevents that invocation's method from running; a later
call attempts initialization again. Regular methods may likewise return a value
or a Future. Exceptions become structured RPC failures. Unawaited background work
is unsupported: handlers must return or await all work they start.
