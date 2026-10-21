use strict;
use warnings;
use Test::More tests => 3;
use Win32::ODBC;

# A failed Connect must report its error and not leave its connection behind.
# The driver manager rejects this option value before it looks up the DSN. It
# does not give a native error number for errors it raises itself, so Connect
# reports 911.

my @connect = Win32::ODBC::ODBCConnect('NoSuchDSN590',
    Win32::ODBC::SQL_ODBC_CURSORS(), 99);
is($connect[0], 1, 'Connect with an invalid option value fails');
is($connect[1], 911, 'Connect reports error number 911');

my @conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections after a failed Connect');
