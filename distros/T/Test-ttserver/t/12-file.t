use strict;
use warnings;
use Test::More;
use Test::ttserver;
use TokyoTyrant;

my $ttserver = Test::ttserver->new('foo.tcb')
    or plan 'skip_all' => $Test::ttserver::errstr;

plan 'tests' => 3;

my $pid_file = $ttserver->pid_file;

my $rdb = TokyoTyrant::RDB->new;
ok( $rdb->open($ttserver->socket), 'connect to ttserver' );
ok( -e $ttserver->{'base_dir'} . '/tmp/foo.tcb', 'dbfile exists' );

undef $ttserver;
ok( !-e $pid_file, 'ttserver is down');
