use strict;
use warnings;
use Test::More tests => 24;
use Win32::ODBC;

# Every XSUB that needs a connection must report an ID with no connection as
# an error. A closed Win32::ODBC object passes ID -1.

my @calls = (
    [SetConnectOption => Win32::ODBC::SQL_AUTOCOMMIT(), 1],
    [GetConnectOption => Win32::ODBC::SQL_AUTOCOMMIT()],
    [GetFunctions     => ()],
    [Transact         => Win32::ODBC::SQL_COMMIT()],
    [GetInfo          => Win32::ODBC::SQL_DBMS_NAME()],
    [DropCursor       => ()],
    [GetTypeInfo      => Win32::ODBC::SQL_ALL_TYPES()],
    [Clone            => ()],
    [GetStmtOption    => Win32::ODBC::SQL_ROWSET_SIZE()],
    [SetStmtOption    => Win32::ODBC::SQL_ROWSET_SIZE(), 1],
    [SetPos           => 1],
    [GetCursorName    => ()],
    [SetCursorName    => 'c1'],
    [GetData          => ()],
    [GetDSN           => ()],
    # Fetch keeps the previous call's error, so an unguarded Fetch right
    # after GetDSN would return GetDSN's error and pass. Execute, which
    # clears it, runs between them.
    [Execute          => 'SELECT 1'],
    [Fetch            => ()],
    [MoreResults      => ()],
    [TableList        => '', '', '%', 'TABLE'],
    [ColumnList       => '', '', '', ''],
    [GetMaxBufSize    => ()],
    [SetMaxBufSize    => 1024],
);

for my $call (@calls) {
    my ($name, @args) = @$call;
    my @r = (1, Win32::ODBC->can("ODBC$name")->(-1, @args));
    is_deeply(\@r, [1, 1, 911, 'No such connection'], "$name with no connection");
}

my @named = (1, Win32::ODBC::ODBCGetDSN(-1, 'NoSuchDSN590'));
is_deeply(\@named, [1, 1, 911, 'Not a valid DSN'], 'GetDSN of a named DSN');

my @conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections after a failed Clone');
