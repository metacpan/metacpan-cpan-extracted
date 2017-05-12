#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 450_service.t

# Testing service_check method using tcp and syn protocols.

use strict;
use warnings;

use Test::More;
use Test::Ping;

use English '-no_match_vars';

SKIP: {
    eval 'use IO::Socket';
    $EVAL_ERROR                    && skip 'No Socket',      26;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port',   26;

    # I'm lazy so I'll just use IO::Socket
    # for the TCP Server stuff instead of doing
    # all that direct socket() junk manually.

#plan tests => 26, ($^O eq 'MSWin32' ? (todo => [18]) :
#		   $^O eq "hpux"    ? (todo => [9, 18]) : ());

    # Start a tcp listen server on ephemeral port
    my $sock1 = IO::Socket::INET->new(
      LocalAddr => '127.0.0.1',
      Proto     => 'tcp',
      Listen    => 8,
    ) or diag("Bind: $OS_ERROR");

    isa_ok( $sock1, 'IO::Socket::INET', 'Created sock1 works' );

    # Start listening on another ephemeral port
    my $sock2 = IO::Socket::INET->new(
      LocalAddr => '127.0.0.1',
      Proto     => 'tcp',
      Listen    => 8,
    ) or diag("Bind: $OS_ERROR");

    isa_ok( $sock2, 'IO::Socket::INET', 'Created sock2 works' );

    my $port1 = $sock1->sockport;
    my $port2 = $sock2->sockport;
    ok( $port1, 'Got sockport 1' );
    ok( $port2, 'Got sockport 2' );

    # Make sure the sockets are listening on different ports.
    isnt( $port1, $port2, 'Make sure sockets listen on different ports' );

    $sock2->close;

    # This is how it should be:
    # 127.0.0.1:$port1 - service ON
    # 127.0.0.1:$port2 - service OFF

    #####
    # First, we test using the "tcp" protocol.
    # (2 seconds should be long enough to connect to loopback.)
    create_ping_object_ok( 'tcp', 2, 'Testing tcp protocol on loopback' );

    # Disable service checking
    $Test::Ping::SERVICE_CHECK = 0;

    # Try on the first port
    $Test::Ping::PORT = $port1;

    ping_ok( '127.0.0.1', 'Make sure it is reachable' );

    TODO: {
        local $TODO = $OSNAME eq 'hpux' ? 'running on HPUX' : undef;
        # Try on the other port
        $Test::Ping::PORT = $port2;

        ping_ok( '127.0.0.1', 'Make sure it is reachable' );
    }

    # Enable service checking
    $Test::Ping::SERVICE_CHECK = 1;

    # Try on the first port
    $Test::Ping::PORT = $port1;

    ping_ok( '127.0.0.1', 'Make sure service is on' );

    # Try on the other port
    $Test::Ping::PORT = $port2;

    ping_not_ok( '127.0.0.1', 'Make sure service is off' );

    # test 11 just finished.

    #####
    # Lastly, we test using the "syn" protocol.
    create_ping_object_ok( 'syn', 2, 'Testing using the syn protocol' );

    # Disable service checking
    $Test::Ping::SERVICE_CHECK = 0;

    # Try on the first port
    $Test::Ping::PORT = $port1;

    # Send SYN
    ping_ok( '127.0.0.1', "Send SYN ($OS_ERROR)" );

    ok( Test::Ping->_ping_object()->ack(), 'IP should be reachable' );

    TODO: {
        local $TODO =
            ( $OSNAME eq 'hpux' || $OSNAME eq 'MSWin32' ) ?
            "Running on $OSNAME"                          :
            undef;

        ok( ! Test::Ping->_ping_object()->ack(), 'No more sockets?' );
    }

    ###
    # Get a fresh object
    create_ping_object_ok( 'syn', 4, 'Get a fresh object' );

    # Disable service checking
    $Test::Ping::SERVICE_CHECK = 1;

    # Try on the other port
    $Test::Ping::PORT = $port2;

    # Send SYN
    ping_ok( '127.0.0.1', "Send SYN ($OS_ERROR)" );

    SKIP: {
            if ($^O =~ /Win/) {
                skip "FIXME: figure out why test fails on Windows", 1;
                ok( Test::Ping->_ping_object()->ack(),
                    'IP should still be reachable' );

            }
    }
    ok( ! Test::Ping->_ping_object()->ack(), 'No more sockets?'             );

    ###
    # Get a fresh object
    create_ping_object_ok( 'syn', 2, 'Get a fresh object' );

    # Enable service checking
    $Test::Ping::SERVICE_CHECK = 1;

    # Try on the first port
    $Test::Ping::PORT = $port1;

    ping_ok( '127.0.0.1', "Send SYN ($OS_ERROR)" );

    ok(
        Test::Ping->_ping_object()->ack(),
        '127.0.0.1 should have service on',
    );

    ok(
        ! Test::Ping->_ping_object()->ack(),
        'No more good sockets?',
    );

    ###
    # Get a fresh object
    create_ping_object_ok( 'syn', 2, 'Get a fresh object' );

    # Enable service checking
    $Test::Ping::SERVICE_CHECK = 1;

    # Try on the other port
    $Test::Ping::PORT = $port2;

    # Send SYN
    ping_ok( '127.0.0.1', "Send SYN ($OS_ERROR)" );

    # No sockets should have service on
    ok(
        ! Test::Ping->_ping_object()->ack(),
        'No sockets should have service on',
    );
}

done_testing();
