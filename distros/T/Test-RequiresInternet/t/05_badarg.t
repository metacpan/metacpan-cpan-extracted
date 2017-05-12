#!perl

use Test::More tests => 1;

delete $ENV{NO_NETWORK_TESTING};

require Test::RequiresInternet;

eval {
        Test::RequiresInternet->import('www.google.com');
};

like(
    $@,
    qr/\QMust supply server and a port pairs. You supplied www.google.com\E/,
    'got exception due to bad arguments',
);
