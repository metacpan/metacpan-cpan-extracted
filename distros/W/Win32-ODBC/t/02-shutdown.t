use strict;
use warnings;
use Test::More tests => 5;
use Win32::ODBC;

# ODBCShutDown() frees this thread's connections; ODBC calls made after it
# must work as they do in a fresh process.

my @bufsize = (1, Win32::ODBC::ODBCGetMaxBufSize(0));

my @shutdown = (1, Win32::ODBC::ODBCShutDown('extra'));
is_deeply(\@shutdown, [1], 'ODBCShutDown returns nothing');

my @conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections after ODBCShutDown');

my @after = (1, Win32::ODBC::ODBCGetMaxBufSize(0));
is_deeply(\@after, \@bufsize, 'GetMaxBufSize after ODBCShutDown');

# A failed Connect as the first call after ODBCShutDown() must not crash.
Win32::ODBC::ODBCShutDown();
my @connect = Win32::ODBC::ODBCConnect('NoSuchDSN590');
is($connect[0], 1, 'Connect to a missing DSN after ODBCShutDown fails');

@conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections after a failed Connect');
