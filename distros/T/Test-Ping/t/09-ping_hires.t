#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 190-alarm.t

# Test to make sure hires feature works.

use strict;
use warnings;

use Test::More;
use Test::Ping;

SKIP: {
    if ( $ENV{'PERL_CORE'} ) {
        if ( ! $ENV{'PERL_TEST_Net_Ping'} ) {
            skip 'Network depedent test', 8;
        }

        chdir 't' if -d 't';
        @INC = qw(../lib);
    }

    eval 'require Socket'          || skip 'No Socket',      8;
    eval 'require Time::HiRes'     || skip 'No Time::HiRes', 8;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port',   8;

    $Test::Ping::PROTO = 'tcp';
    create_ping_object_ok( 'tcp', 'Create proper Net::Ping object' );

    # these are internal package variables of Net::Ping
    # and not hash keys, so they have to be tested this way

    cmp_ok( $Test::Ping::HIRES, '==', 1, 'Net::Ping uses Time::HiRes by default' );
    $Test::Ping::HIRES = 0;
    cmp_ok( $Test::Ping::HIRES, '==', 0, 'Disabling HIRES works' );
    $Test::Ping::HIRES = 1;
    cmp_ok( $Test::Ping::HIRES, '==', 1, 'Re-enabling HIRES works' );

    my ( $ret, $duration ) =
        ping_ok( 'localhost', 'Test on the default port' );

    ok( $ret, 'localhost should always be reachable, right?' );

    # It is extremely likely that the duration contains a decimal
    # point if Time::HiRes is functioning properly, except when it
    # is fast enough to be "0", or slow enough to be exactly "1".
    like( $duration, qr/\.|^[01]$/, 'Duration likely has a decimal point' );
};

done_testing();
