#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list datacenters' => sub {
    my $fixture = load_fixture('datacenters_list');

    my $cloud = mock_cloud(
        'GET /datacenters' => $fixture,
    );

    my $datacenters = $cloud->datacenters->list;

    is(ref $datacenters, 'ARRAY', 'returns array');
    is(scalar @$datacenters, 3, 'three datacenters');
    is($datacenters->[0]->name, 'fsn1-dc14', 'first datacenter name');
    is($datacenters->[0]->location, 'fsn1', 'first datacenter location');
};

subtest 'get datacenter by id' => sub {
    my $fixture = load_fixture('datacenters_get');

    my $cloud = mock_cloud(
        'GET /datacenters/1' => $fixture,
    );

    my $datacenter = $cloud->datacenters->get(1);

    is($datacenter->id, 1, 'datacenter id');
    is($datacenter->name, 'fsn1-dc14', 'datacenter name');
    is($datacenter->location, 'fsn1', 'datacenter location');
};

subtest 'get datacenter by name' => sub {
    my $fixture = load_fixture('datacenters_list');

    my $cloud = mock_cloud(
        'GET /datacenters' => $fixture,
    );

    my $datacenter = $cloud->datacenters->get_by_name('nbg1-dc3');

    is($datacenter->name, 'nbg1-dc3', 'datacenter name');
    is($datacenter->location_data->{city}, 'Nuremberg', 'datacenter city');
};

subtest 'get datacenter by name - not found' => sub {
    my $fixture = load_fixture('datacenters_list');

    my $cloud = mock_cloud(
        'GET /datacenters' => $fixture,
    );

    my $datacenter = $cloud->datacenters->get_by_name('nonexistent');

    ok(!defined $datacenter, 'returns undef for not found');
};

done_testing;
