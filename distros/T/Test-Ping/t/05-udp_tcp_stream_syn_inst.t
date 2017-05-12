#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original names: 120-udp_inst.t, 130-tcp_inst.t, 140-stream_inst,
#   150-syn_inst.t

use strict;
use warnings;

use Test::More tests => 8;
use Test::Ping;

sub test_proto {
    my $proto = shift;
    $Test::Ping::PROTO = $proto;
    Test::Ping::_has_var_ok( 'proto', $proto, "Can be initialized for $proto" );
    create_ping_object_ok( $proto, "Created Net::Ping object with $proto" );
}

SKIP: {
    eval 'require Socket'          || skip 'No Socket',    2;
    getservbyname( 'echo', 'udp' ) || skip 'No echo port', 2;

    test_proto('udp');
    test_proto('tcp');
}

SKIP: {
    eval 'require Socket'          || skip 'No Socket',    2;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port', 2;

    test_proto('stream');
    test_proto('syn');
}
