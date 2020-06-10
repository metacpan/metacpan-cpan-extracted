#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 200_ping_tcp.t

use strict;
use warnings;

use Test::More;
use Test::Ping;

SKIP: {
    if ( $ENV{'PERL_CORE'} ) {
        if ( ! $ENV{'PERL_TEST_Net_Ping'} ) {
            skip 'Network dependent test', 10;
        }

        chdir 't' if -d 't';
        @INC = qw(../lib);
    }

    eval 'require Socket'          || skip 'No Socket',    10;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port', 10;

    # Remote network test using tcp protocol.
    #
    # NOTE:
    #   Network connectivity will be required for all tests to pass.
    #   Firewalls may also cause some tests to fail, so test it
    #   on a clear network.  If you know you do not have a direct
    #   connection to remote networks, but you still want the tests
    #   to pass, use the following:
    #
    # $ PERL_CORE=1 make test

    $Test::Ping::PROTO   = 'tcp';
    $Test::Ping::TIMEOUT = 9;

    create_ping_object_ok( 'tcp', 9, 'Create proper Net::Ping object' );
    ping_ok( 'localhost', 'Test on the default port' );

    # Change to use the more common web port.
    # This will pull from /etc/services on UNIX.
    # (Make sure getservbyname works in scalar context.)
    $Test::Ping::PORT = ( getservbyname( 'http', 'tcp' ) || 80 );

    ping_ok( 'localhost', 'Test localhost on the web port' );

    ping_not_ok( '203.0.113.90', 'Documentation address; non-routable' );

    # Test a few remote servers
    # Hopefully they are up when the tests are run.

    ping_ok( 'facebook.com', 'facebook.com' );
    ping_ok( 'google.ca',    'google.ca' );
}

done_testing();
