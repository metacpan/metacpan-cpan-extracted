use strict;
use warnings;
use Test::More tests => 6;
use Win32::ODBC;

# The methods hide which values an XSUB returns, so call the XSUBs directly
# and check that a value listed before the call is still in the result.

my @info = (1, Win32::ODBC::Info());
is(scalar @info, 9, 'Info returns eight values');

my @conns = (1, Win32::ODBC::ODBCGetConnections());
is_deeply(\@conns, [1, 0], 'GetConnections lists only the default connection');

my @bufsize = (1, Win32::ODBC::ODBCGetMaxBufSize(999));
is_deeply(\@bufsize, [1, 1, 911, 'No such connection'], 'GetMaxBufSize on a missing connection');

my @usage = (1, Win32::ODBC::ODBCRowCount());
is_deeply(\@usage, [1, 999, "usage: (\$Err, \$NumOfRows) = ODBC_RowCount(\$Connection)\n"],
    'usage error without arguments');

@usage = (1, Win32::ODBC::ODBCGetConnections('extra'));
is_deeply(\@usage, [1, 999, "usage: (\@ConnectionList) = ODBC_GetConnections()\n"],
    'usage error with an argument');

my @init = (1, Win32::ODBC::ODBCInit('extra'));
is_deeply(\@init, [1], 'ODBCInit returns nothing');
