# WebDyne::Cloudflare::Hyperdrive::Statement

Create with `$db_or->prepare($sql, undef)`. A statement is a local SQL/binding/result
object, not a persistent server prepared statement. PostgreSQL execution uses the
extended query protocol with bound values.

```perl
my $statement_or=$db_or->prepare('SELECT id, name FROM customers WHERE name=$1');
$statement_or->bind_param(1, $name);
await $statement_or->execute();
while (my $row_hr=$statement_or->fetchrow_hashref()) {
    # Use the buffered row.
}
$statement_or->finish();
```

## Binding and execution

`bind_param($position, $value, $type)` synchronously stores a parameter and returns
1. Positions start at 1 and must be contiguous at execution. Type is optional:
undef uses automatic scalar/boolean/Blob encoding; `text` accepts scalar text,
`boolean` accepts JSON booleans or 0/1, and `bytea` accepts bytes or a Blob wrapper.
Undef values always encode SQL NULL. Hints persist when binding again without a
hint or supplying execute values. Numeric DBI SQL_* constants are not supported.
Use SQL casts for PostgreSQL type selection; these hints describe value encoding.

`execute(@bind)` returns a Future resolving to affected-row count, true `0E0` for
zero, or -1 when unknown. Supplied arguments replace stored bindings, retaining
position-specific hints; `execute()` with no arguments reuses stored bindings.
Each execution clears old results and resets fetching. Failed execution cannot
expose stale rows. A statement cannot execute, rebind, fetch or finish while its
execution is pending. The host diagnoses mismatched SQL placeholder counts.

## Buffered results

`fetchrow_arrayref()` and `fetchrow_hashref()` synchronously consume the next row,
returning undef when exhausted. Array rows preserve duplicate columns; hash rows
use the last column with that name, even if its value is NULL. Returned row
containers are copies.

`fetchall_arrayref()` consumes remaining array rows. `fetchall_arrayref({})`
consumes remaining hash rows. Only undef or an empty hash is accepted; DBI's
other slice forms and row-count arguments are not implemented. Exhaustion returns
an empty array. No additional SQL or network I/O occurs during fetching.

`rows()` gives the last execution's count using execute's count convention.
`columns()` returns a copy of ordered `{ name, oid }` metadata, and `command()`
returns the PostgreSQL command tag. Before execution or after finish these return
-1, an empty array, and undef respectively.

`finish()` releases local results/metadata and returns 1. Bindings remain available
for reuse. Unexecuted or finished statements have no rows. Disconnect invalidates
all associated statements, and transaction callback statements expire with their
facade; subsequent operations throw even if results were buffered earlier.

## MySQL result metadata

`insert_id()` returns the exact decimal insert ID string from the last MySQL DML
result, including `"0"` when the driver reports no generated ID. `affected_rows()`
returns its affectedRows count and `warning_count()` its warning count. These
accessors return undef before execution, after finish, after failed execution,
or when the result omits that metadata (including PostgreSQL results).
MySQL columns carry `driver => 'mysql'`, `type`, `flags`, and `charset`, while
PostgreSQL columns retain `oid`. Both retain ordered names and duplicate columns.
