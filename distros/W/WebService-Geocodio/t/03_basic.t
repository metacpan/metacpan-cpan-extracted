#!/usr/bin/env perl

use strict;
use Test::More;
use WebService::Geocodio;
use WebService::Geocodio::Location;

BEGIN {
    if (! $ENV{GEOCODIO_API_KEY} ) {
        plan skip_all => "Set GEOCODIO_API_KEY to run these tests.";
    }
    else {
        plan tests => 5;
    }
};

my $geo = WebService::Geocodio->new(
    api_key => $ENV{GEOCODIO_API_KEY}
);

isa_ok($geo, 'WebService::Geocodio');

is($geo->geocode(), undef, "Return undef if no locations");

my $loc = WebService::Geocodio::Location->new('1060 W Addison St, Chicago, IL');
$geo->add_location($loc);
my @r = $geo->geocode();

is(scalar @r, 1, "Got 1 result in array");

my $r = $geo->geocode();
is($r->[0]->state, 'IL', "Got right state");

$geo->clear_locations;

my $loc1 = WebService::Geocodio::Location->new(
    number => 1600,
    street => 'Pennsylvania',
    suffix => 'Avenue',
    city => 'Washington',
    state => 'DC',
);

$geo->add_location($loc1);

$r = $geo->geocode();

is($r->[0]->state, 'DC', "Got right state");
