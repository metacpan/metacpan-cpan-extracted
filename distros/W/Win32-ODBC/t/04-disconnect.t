use strict;
use warnings;
use Test::More tests => 4;
use Win32::ODBC;

# Connection 0 is the thread's default object; Disconnect must not delete it.

my @bufsize = (1, Win32::ODBC::ODBCGetMaxBufSize(0));

my @bare = Win32::ODBC::ODBCDisconnect();
is($bare[0], 1, 'Disconnect without a connection fails');

my @zero = Win32::ODBC::ODBCDisconnect(0);
is($zero[0], 1, 'Disconnect of connection 0 fails');

my @conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections after Disconnect');

my @after = (1, Win32::ODBC::ODBCGetMaxBufSize(0));
is_deeply(\@after, \@bufsize, 'GetMaxBufSize after Disconnect');
