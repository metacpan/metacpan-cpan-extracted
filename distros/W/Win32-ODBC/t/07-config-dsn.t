use strict;
use warnings;
use Test::More tests => 1;
use Win32::ODBC;

# Without attributes, ConfigDSN passes SQLConfigDataSource() an empty list.
# NoSuchDriver590 does not exist, so the call fails without adding a DSN.
my @r = (1, Win32::ODBC::ODBCConfigDSN(0, Win32::ODBC::ODBC_ADD_DSN(), 'NoSuchDriver590'));
is_deeply(\@r, [1, 0, 0], 'ConfigDSN without attributes');
