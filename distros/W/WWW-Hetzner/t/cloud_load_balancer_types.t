#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list load balancer types' => sub {
    my $fixture = load_fixture('load_balancer_types_list');

    my $cloud = mock_cloud(
        'GET /load_balancer_types' => $fixture,
    );

    my $types = $cloud->load_balancer_types->list;

    is(ref $types, 'ARRAY', 'returns array');
    is(scalar @$types, 3, 'three types');
    isa_ok($types->[0], 'WWW::Hetzner::Cloud::LoadBalancerType');
    is($types->[0]->id, 1, 'type id');
    is($types->[0]->name, 'lb11', 'type name');
    is($types->[0]->description, 'LB11', 'type description');
    is($types->[0]->max_connections, 20000, 'max connections');
    is($types->[0]->max_services, 5, 'max services');
    is($types->[0]->max_targets, 25, 'max targets');
    is($types->[0]->max_assigned_certificates, 10, 'max assigned certificates');
    ok(!$types->[0]->deprecated, 'not deprecated');
    is($types->[1]->name, 'lb21', 'second type name');
    is($types->[2]->name, 'lb31', 'third type name');
};

subtest 'load balancer type prices' => sub {
    my $fixture = load_fixture('load_balancer_types_list');

    my $cloud = mock_cloud(
        'GET /load_balancer_types' => $fixture,
    );

    my $prices = $cloud->load_balancer_types->list->[0]->prices;

    is(ref $prices, 'ARRAY', 'prices is an array');
    is(scalar @$prices, 1, 'one price entry');
    is($prices->[0]{location}, 'fsn1', 'price location');
    is($prices->[0]{price_monthly}{gross}, '5.8310', 'monthly gross price');
    is($prices->[0]{price_hourly}{net}, '0.0079', 'hourly net price');
};

subtest 'get load balancer type by id' => sub {
    my $fixture = load_fixture('load_balancer_types_get');

    my $cloud = mock_cloud(
        'GET /load_balancer_types/1' => $fixture,
    );

    my $type = $cloud->load_balancer_types->get(1);

    isa_ok($type, 'WWW::Hetzner::Cloud::LoadBalancerType');
    is($type->id, 1, 'type id');
    is($type->name, 'lb11', 'type name');
    is($type->max_targets, 25, 'max targets');
};

subtest 'get load balancer type by id - id required' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->load_balancer_types->get };
    like($@, qr/Load Balancer Type ID required/, 'croaks without id');
};

subtest 'get load balancer type by name' => sub {
    my $fixture = load_fixture('load_balancer_types_list');

    my $cloud = mock_cloud(
        'GET /load_balancer_types' => $fixture,
    );

    my $type = $cloud->load_balancer_types->get_by_name('lb21');

    isa_ok($type, 'WWW::Hetzner::Cloud::LoadBalancerType');
    is($type->id, 2, 'type id');
    is($type->max_connections, 75000, 'max connections');
};

subtest 'get load balancer type by name - not found' => sub {
    my $fixture = load_fixture('load_balancer_types_list');

    my $cloud = mock_cloud(
        'GET /load_balancer_types' => $fixture,
    );

    my $type = $cloud->load_balancer_types->get_by_name('nonexistent');

    ok(!defined $type, 'returns undef for not found');
};

subtest 'load balancer type data' => sub {
    my $fixture = load_fixture('load_balancer_types_get');

    my $cloud = mock_cloud(
        'GET /load_balancer_types/1' => $fixture,
    );

    my $data = $cloud->load_balancer_types->get(1)->data;

    is(ref $data, 'HASH', 'data returns hashref');
    is($data->{name}, 'lb11', 'data name');
    is($data->{max_assigned_certificates}, 10, 'data max assigned certificates');
    is($data->{prices}[0]{location}, 'fsn1', 'data carries prices');
};

done_testing;
