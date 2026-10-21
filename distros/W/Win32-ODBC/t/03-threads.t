use strict;
use warnings;
use Config;
use Test::More;
BEGIN {
    plan skip_all => 'perl lacks ithreads' unless $Config{useithreads};
}
use threads;
use Win32::ODBC;

plan tests => 3;

# A thread created after the module loaded never ran the module's boot code.

my $thread = threads->create({context => 'list'},
    sub { (1, Win32::ODBC::ODBCGetConnections()) });
my @conns = $thread->join;
is_deeply(\@conns, [1, 0], 'GetConnections in a new thread');

$thread = threads->create({context => 'list'}, sub {
    my @connect = Win32::ODBC::ODBCConnect('NoSuchDSN590');
    ($connect[0], [Win32::ODBC::ODBCGetConnections()]);
});
my ($error, $conns) = $thread->join;
is($error, 1, 'Connect to a missing DSN in a new thread fails');
is_deeply($conns, [0], 'GetConnections in that thread after the failed Connect');
