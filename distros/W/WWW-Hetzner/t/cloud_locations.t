#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list locations' => sub {
    my $fixture = load_fixture('locations_list');

    my $cloud = mock_cloud(
        'GET /locations' => $fixture,
    );

    my $locations = $cloud->locations->list;

    is(ref $locations, 'ARRAY', 'returns array');
    is(scalar @$locations, 3, 'three locations');
    is($locations->[0]{name}, 'fsn1', 'first location name');
    is($locations->[0]{description}, 'Falkenstein DC Park 1', 'first location description');
    is($locations->[0]{country}, 'DE', 'first location country');
};

subtest 'get location by name' => sub {
    my $fixture = load_fixture('locations_list');

    my $cloud = mock_cloud(
        'GET /locations' => $fixture,
    );

    my $location = $cloud->locations->get_by_name('nbg1');

    is($location->{name}, 'nbg1', 'location name');
    is($location->{city}, 'Nuremberg', 'location city');
};

subtest 'get location by id' => sub {
    my $fixture = load_fixture('locations_get');

    my $cloud = mock_cloud(
        'GET /locations/1' => $fixture,
    );

    my $location = $cloud->locations->get(1);

    is($location->{id}, 1, 'location id');
    is($location->{name}, 'fsn1', 'location name');
    is($location->{city}, 'Falkenstein', 'location city');
};

done_testing;
