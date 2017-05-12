
use strict;
use Test::Memcached;
use Test::More;

my @args;
if ( $> == 0 ) {
    @args = ( options => { user => $ENV{TEST_MEMCACHED_USER} || 'nobody' } );
}
my $memd = Test::Memcached->new(@args);
if (ok($memd)) {
    diag("Detected memcached " . $memd->memcached_version);
    ok $memd->memcached_version;
    ok $memd->memcached_major_version;
    ok $memd->memcached_minor_version;
    ok $memd->memcached_micro_version;

    $memd->start;

    sleep 2;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $memd->option('bind'),
        PeerPort => $memd->option('tcp_port'),
    );

    ok $socket;
    my $pid = $memd->pid;
    ok $pid;

    $memd->stop;

    ok ! kill 0 => $pid;
}

done_testing;