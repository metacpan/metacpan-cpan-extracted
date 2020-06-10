#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 410_syn_host.t

# Same as 400_ping_syn.t but testing ack( $host ) instead of ack( ).

use strict;
use warnings;

use Test::More;
use Test::Ping;

use English '-no_match_vars';

SKIP: {
    if ( $ENV{'PERL_CORE'} ) {
        if ( ! $ENV{'PERL_TEST_Net_Ping'} ) {
            skip 'Network depedent test', 8 * 3 + 4;
        }

        chdir 't' if -d 't';
        @INC = qw(../lib);
    }

    eval 'use Test::Timer';
    $EVAL_ERROR                    && skip 'No Test::Timer', 8 * 3 + 4;
    eval 'require Socket'          || skip 'No Socket',      8 * 3 + 4;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port',   8 * 3 + 4;
    getservbyname( 'http', 'tcp')  || skip 'No HTTP port',   8 * 3 + 4;

    # Remote network test using syn protocol.
    #
    # NOTE:
    #   Network connectivity will be required for all tests to pass.
    #   Firewalls may also cause some tests to fail, so test it
    #   on a clear network.  If you know you do not have a direct
    #   connection to remote networks, but you still want the tests
    #   to pass, use the following:
    #
    # $ PERL_CORE=1 make test

    # Try a few remote servers
    my %webs = (
        # Documentation address; non-routable
        '203.0.113.90'       => 0,

        # Hopefully all these web ports are open
        'www.geocities.com.'   => 1,
        'www.freeservers.com.' => 1,
        'yahoo.com.'           => 1,
        'www.yahoo.com.'       => 1,
        'www.about.com.'       => 1,
        'www.microsoft.com.'   => 1,
    );

    time_atmost(
        sub {
            create_ping_object_ok(
                'syn',
                10,
                'Create new ping object with syn'
            );
        },
        50,
        'Creating object',
    );

    # Change to use the more common web port.
    # (Make sure getservbyname works in scalar context.)
    my $new_port      = getservbyname( 'http', 'tcp' );
    $Test::Ping::PORT = $new_port;
    Test::Ping::_has_var_ok(
        'port_num',
        $new_port,
        'Change to use the more common web port',
    );

    foreach my $host ( keys %webs ) {
        # ping() does dns resolution and
        # only sends the SYN at this point
        my $bad_host = Test::Ping->_ping_object()->{'bad'}->{$host} || q{};
        time_atmost(
            sub {
                ping_ok( $host, "Resolving $host $bad_host" );
            },
            50,
            'Plenty for a DNS lookup',
        );
    }

    time_atmost (
        sub {
            foreach my $host ( sort keys %webs ) {
                my $on       = Test::Ping->_ping_object()->ack($host);
                my $bad_host =
                    Test::Ping->_ping_object()->{'bad'}->{$host} || q{};
                my $status   = $bad_host ? 'failing' : 'succeeding';
                ok(
                    (  $on &&  $webs{$host} ) ||
                    ( !$on && !$webs{$host} ),
                    "Testing http//$host/ and $status [$bad_host]",
                );

                delete $webs{$host};
            }
        },
        20,
        'Syn test',
    );
}

done_testing();
