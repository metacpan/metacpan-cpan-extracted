#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::Cloud::API::Pricing;

subtest 'get pricing' => sub {
    my $fixture = load_fixture('pricing_get');

    my $cloud = mock_cloud(
        'GET /pricing' => $fixture,
    );

    my $pricing = $cloud->pricing->get;

    isa_ok($pricing, 'WWW::Hetzner::Cloud::Pricing');
    is($pricing->currency, 'EUR', 'currency');
    is($pricing->vat_rate, '19.00', 'vat rate');
    is($pricing->image->{price_per_gb_month}{gross}, '0.0142', 'image price per GB/month');
    is($pricing->volume->{price_per_gb_month}{net}, '0.0440', 'volume price per GB/month');
    is($pricing->server_backup->{percentage}, '20.0', 'server backup percentage');
};

subtest 'pricing is a singleton, not a list' => sub {
    ok(WWW::Hetzner::Cloud::API::Pricing->can('get'), 'controller has get');
    ok(!WWW::Hetzner::Cloud::API::Pricing->can('list'),
        'controller has no list -- /pricing returns one object');
};

subtest 'pricing type prices' => sub {
    my $fixture = load_fixture('pricing_get');

    my $cloud = mock_cloud(
        'GET /pricing' => $fixture,
    );

    my $pricing = $cloud->pricing->get;

    is(ref $pricing->server_types, 'ARRAY', 'server_types is an array');
    is($pricing->server_types->[0]{name}, 'cx23', 'server type name');
    is($pricing->server_types->[0]{prices}[0]{location}, 'fsn1', 'server type price location');
    is($pricing->server_types->[0]{prices}[0]{price_monthly}{gross}, '4.5101',
        'server type monthly gross price');

    is(ref $pricing->load_balancer_types, 'ARRAY', 'load_balancer_types is an array');
    is($pricing->load_balancer_types->[0]{name}, 'lb11', 'load balancer type name');
    is($pricing->load_balancer_types->[0]{prices}[0]{price_hourly}{net}, '0.0079',
        'load balancer type hourly net price');
};

subtest 'pricing ip prices' => sub {
    my $fixture = load_fixture('pricing_get');

    my $cloud = mock_cloud(
        'GET /pricing' => $fixture,
    );

    my $pricing = $cloud->pricing->get;

    is($pricing->primary_ips->[0]{type}, 'ipv4', 'primary ip type');
    is($pricing->primary_ips->[0]{prices}[0]{price_monthly}{net}, '0.5000',
        'primary ip monthly net price');
    is($pricing->floating_ips->[0]{type}, 'ipv4', 'floating ip type');
    is($pricing->floating_ips->[0]{prices}[0]{price_monthly}{gross}, '1.1900',
        'floating ip monthly gross price');
    is($pricing->floating_ip->{price_monthly}{gross}, '1.1900',
        'legacy floating_ip price still readable');
    ok(!defined $pricing->traffic, 'legacy traffic absent from current responses');
};

subtest 'pricing data' => sub {
    my $fixture = load_fixture('pricing_get');

    my $cloud = mock_cloud(
        'GET /pricing' => $fixture,
    );

    my $data = $cloud->pricing->get->data;

    is(ref $data, 'HASH', 'data returns hashref');
    is($data->{currency}, 'EUR', 'data currency');
    is($data->{server_backup}{percentage}, '20.0', 'data server backup');
    is($data->{load_balancer_types}[0]{name}, 'lb11', 'data load balancer types');
};

done_testing;
