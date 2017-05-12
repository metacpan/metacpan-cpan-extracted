#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;

BEGIN {
    use_ok( 'WebService::Megaplan' ) || print "Bail out!\n";
}

SKIP: {
    skip 'No env MEGAPLAN_LOGIN', 4     if(! $ENV{MEGAPLAN_LOGIN});
    skip 'No env MEGAPLAN_PASSWORD', 4  if(! $ENV{MEGAPLAN_PASSWORD});
    skip 'No env MEGAPLAN_HOST', 4      if(! $ENV{MEGAPLAN_HOST});

    my $api = WebService::Megaplan->new(
                    login => $ENV{MEGAPLAN_LOGIN},
                    password => $ENV{MEGAPLAN_PASSWORD},
                    hostname => $ENV{MEGAPLAN_HOST},
                    use_ssl  => 1,
                );
    ok($api, 'object created');

    ok($api->authorize(), 'login successful');

    ok($api->secret_key, 'got SecretKey');
    ok($api->access_id, 'got AccessID');
}

diag( "Testing WebService::Megaplan $WebService::Megaplan::VERSION, Perl $], $^X" );
