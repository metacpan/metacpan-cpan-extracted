#!/usr/bin/perl -s

use strict; use warnings;
use Test::More;
use lib 'lib';

BEGIN {
    if ( $ENV{ONLINE_ENABLED} ) {
        plan tests => 6;
    } else {
        plan skip_all => 'Online tests disabled.  Set export ONLINE_ENABLED=1 to enable';
        exit;
    }
}

use_ok('Tie::DNS');

#Test caching
my %dns;
eval {
    tie %dns, 'Tie::DNS', { cache => 100 };
};
ok((not $@), 'tie %dns, "Tie::DNS", { cache => 100 };' );
my $ip = eval {
    return $dns{'www.google.com'};
};
ok((not $@), '$ip = $dns{"www.google.com"}');
ok(
    $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
    'www.google.com lookup (testing cached)'
);
my $ip2 = eval {
    return $dns{'www.google.com'};
};
ok((not $@), '$ip2 = $dns{"www.google.com"}');
ok($ip2 eq $ip, 'www.google.com lookup (testing cached)');
