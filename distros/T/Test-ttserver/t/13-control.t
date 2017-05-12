use strict;
use warnings;
use Test::More;
use Test::ttserver;

my $ttserver = Test::ttserver->new
    or plan 'skip_all' => $Test::ttserver::errstr;

plan 'tests' => 12;

ok( !$ttserver->start, 'do nothing' );
ok( $ttserver->is_up, 'active flag on' );
ok( $ttserver->pid, 'pid ' . $ttserver->pid );
ok( -e $ttserver->pid_file, 'pid file exists' );

my $pid      = $ttserver->pid;
my $pid_file = $ttserver->pid_file;

cmp_ok( $ttserver->stop, '==', 1, 'ttserver is down' );
ok( $ttserver->is_down, 'active flag off' );
ok( !-e $pid_file, 'pid file not exists' );
SKIP: {
    skip('Your operating system does not have proc', 1) unless -d '/proc';
    ok( !-e "/proc/$pid", 'process does not exists' );
}

ok( $ttserver->start, 'ttserver is up' );
ok( $ttserver->is_up, 'active flag on' );
ok( $ttserver->pid, 'pid ' . $ttserver->pid );
ok( -e $ttserver->pid_file, 'pid file exists' );
