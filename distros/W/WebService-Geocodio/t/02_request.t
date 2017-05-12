#!/usr/bin/env perl

use strict;
use Test::More;
use WebService::Geocodio;

BEGIN { 
    if (! $ENV{GEOCODIO_API_KEY} ) {
        plan skip_all => "Set GEOCODIO_API_KEY to run these tests.";
    }
    else {
        plan tests => 7;
    }
};
    
my $geo = WebService::Geocodio->new(
    api_key => $ENV{GEOCODIO_API_KEY}
);

isa_ok($geo, 'WebService::Geocodio');

my @response = $geo->geocode('77056', '77450');

is($response[0]->city, "Houston", "Got right city");
is($response[0]->state, "TX", "Got right state");
is($response[0]->accuracy, 1, "Got right accuracy");
is($response[1]->city, "Katy", "Got right city");
is($response[1]->state, "TX", "Got right state");
is($response[1]->accuracy, 1, "Got right accuracy");
