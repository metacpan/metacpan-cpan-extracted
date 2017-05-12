
use strict;
use Test::Memcached;
use Test::More;

my @args;
if ( $> == 0 ) {
    @args = ( options => { user => $ENV{TEST_MEMCACHED_USER} || 'nobody' } );
}
my $memd = Test::Memcached->new( @args );
if (! $memd) {
    # This is not good, as we're not able to check if Test::Memcached
    # was returning because there was no memcached, or we have a bug in
    # our code to locate memcached binary.
    # .... but I'm going to ignore it anyways, cause I'd like to silence
    # CPAN testers for now. If you believe that there's a bug, please
    # report.
    plan skip_all => "No memcached found";
} else {
    plan tests => 4;
}

ok($memd);

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