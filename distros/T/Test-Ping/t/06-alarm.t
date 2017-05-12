#!perl -T

# this is a (little) cleaner version of a Net::Ping test(s)
# original name: 190-alarm.t

# Test to make sure alarm / SIGALM does not interfere
# with Net::Ping.  (This test was derived to ensure
# compatibility with the "spamassassin" utility.)
# Based on code written by radu@netsoft.ro (Radu Greab).

use strict;
use warnings;

use Test::More tests => 2;
use Test::Ping;

use English '-no_match_vars';

SKIP: {
    $ENV{PERL_TEST_Net_Ping}       || skip 'network dependent test', 2;
    eval 'require Socket'          || skip 'No Socket',              2;
    getservbyname( 'echo', 'tcp' ) || skip 'No echo port',           2;
    eval 'use Test::Timer';
    $EVAL_ERROR                    && skip 'No Test::Timer',         2;

    my $test = sub { Test::Ping->_ping_object()->ping('172.29.249.249') };

    $Test::Ping::PROTO = 'tcp';
    time_between( $test, 4, 6, 'Timeout not enabled' );

    $Test::Ping::TIMEOUT = 2;
    time_atmost( $test, $Test::Ping::TIMEOUT + 1, 'Timeout enabled' );
}

