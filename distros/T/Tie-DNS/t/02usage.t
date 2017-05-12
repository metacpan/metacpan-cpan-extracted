#!/usr/bin/perl -s

use strict; use warnings;
use Test::More;
use lib 'lib';

BEGIN {
    if ( $ENV{ONLINE_ENABLED} ) {
        plan tests => 4;
    } else {
        plan skip_all => 'Online tests disabled.  Set export ONLINE_ENABLED=1 to enable';
        exit;
    }
}

use_ok('Tie::DNS');

my %dns;
eval {
    tie %dns, 'Tie::DNS';
};
ok((not $@), 'Successful tie of Tie::DNS');

my $ip = eval {
    return $dns{'www.google.com'};
};
ok((not $@), '$ip = $dns{"www.google.com"}');
ok($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, 'www.google.com lookup' );
