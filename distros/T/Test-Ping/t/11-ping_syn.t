#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 400_ping_syn.t

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
      # Hopefully this is never a routeable host
      '172.29.249.249'       => 0,

      # Hopefully all these web ports are open
      'facebook.com.'  => 1,
      'google.ca.'     => 1,
      'microsoft.com.' => 1,
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
            20,
            'Plenty for a DNS lookup',
        );
    }

    time_atmost(
        sub {
            while ( my $host = Test::Ping->_ping_object()->ack() ) {
                ok( $webs{$host}, "Checking ack: http://$host/" );
                delete $webs{$host};
            }
        },
        20,
        'Up to 20 seconds',
    );

    foreach my $host ( keys %webs ) {
        my $bad_host = Test::Ping->_ping_object()->{'bad'}->{$host} || '';
        ok( ! $webs{$host}, "DOWN: http://$host/ [$bad_host]" );
    }
}

done_testing();
