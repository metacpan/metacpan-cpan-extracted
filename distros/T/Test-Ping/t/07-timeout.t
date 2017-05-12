#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Test::Ping;

$Test::Ping::TIMEOUT = 5;

my $bad_ip = '172.29.249.249';

SKIP: {

    if ( Test::Ping->_ping_object()->ping($bad_ip) ) {
        skip 'our bad IP is actually working...', 1;
    }

    ping_not_ok( $bad_ip, 'Bad IP cannot ping' );
}

