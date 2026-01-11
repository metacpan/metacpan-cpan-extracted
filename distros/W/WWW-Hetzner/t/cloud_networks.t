#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list networks' => sub {
    my $fixture = load_fixture('networks_list');

    my $cloud = mock_cloud(
        'GET /networks' => $fixture,
    );

    my $networks = $cloud->networks->list;

    is(ref $networks, 'ARRAY', 'returns array');
    is(scalar @$networks, 1, 'one network');
    isa_ok($networks->[0], 'WWW::Hetzner::Cloud::Network');
    is($networks->[0]->id, 100, 'network id');
    is($networks->[0]->name, 'my-network', 'network name');
    is($networks->[0]->ip_range, '10.0.0.0/8', 'ip range');
    is(scalar @{$networks->[0]->servers}, 2, 'two servers');
    is(scalar @{$networks->[0]->subnets}, 1, 'one subnet');
    is(scalar @{$networks->[0]->routes}, 1, 'one route');
};

subtest 'get network' => sub {
    my $fixture = load_fixture('networks_get');

    my $cloud = mock_cloud(
        '/networks/100' => $fixture,
    );

    my $network = $cloud->networks->get(100);

    isa_ok($network, 'WWW::Hetzner::Cloud::Network');
    is($network->id, 100, 'network id');
    is($network->name, 'my-network', 'network name');
    is($network->subnets->[0]{ip_range}, '10.0.1.0/24', 'subnet ip range');
    is($network->routes->[0]{destination}, '10.100.1.0/24', 'route destination');
};

subtest 'create network' => sub {
    my $fixture = load_fixture('networks_create');

    my $cloud = mock_cloud(
        'POST /networks' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'new-network', 'name in request');
            is($body->{ip_range}, '192.168.0.0/16', 'ip_range in request');

            return $fixture;
        },
    );

    my $network = $cloud->networks->create(
        name     => 'new-network',
        ip_range => '192.168.0.0/16',
    );

    isa_ok($network, 'WWW::Hetzner::Cloud::Network');
    is($network->id, 200, 'new network id');
    is($network->name, 'new-network', 'new network name');
};

subtest 'delete network' => sub {
    my $cloud = mock_cloud(
        'DELETE /networks/100' => {},
    );

    my $result = $cloud->networks->delete(100);
    ok(1, 'delete succeeded');
};

subtest 'create network requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->networks->create() };
    like($@, qr/name required/, 'name required');

    eval { $cloud->networks->create(name => 'test') };
    like($@, qr/ip_range required/, 'ip_range required');
};

subtest 'add subnet' => sub {
    my $fixture = load_fixture('networks_action');

    my $cloud = mock_cloud(
        'POST /networks/100/actions/add_subnet' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ip_range}, '10.0.2.0/24', 'ip_range in request');
            is($opts{body}{network_zone}, 'eu-central', 'network_zone in request');
            is($opts{body}{type}, 'cloud', 'type in request');
            return $fixture;
        },
    );

    my $result = $cloud->networks->add_subnet(100,
        ip_range     => '10.0.2.0/24',
        network_zone => 'eu-central',
        type         => 'cloud',
    );
    is($result->{action}{command}, 'add_subnet', 'action command');
};

subtest 'delete subnet' => sub {
    my $fixture = load_fixture('networks_action');
    $fixture->{action}{command} = 'delete_subnet';

    my $cloud = mock_cloud(
        'POST /networks/100/actions/delete_subnet' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ip_range}, '10.0.2.0/24', 'ip_range in request');
            return $fixture;
        },
    );

    my $result = $cloud->networks->delete_subnet(100, '10.0.2.0/24');
    is($result->{action}{command}, 'delete_subnet', 'action command');
};

subtest 'add route' => sub {
    my $fixture = load_fixture('networks_action');
    $fixture->{action}{command} = 'add_route';

    my $cloud = mock_cloud(
        'POST /networks/100/actions/add_route' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{destination}, '10.200.0.0/16', 'destination in request');
            is($opts{body}{gateway}, '10.0.0.1', 'gateway in request');
            return $fixture;
        },
    );

    my $result = $cloud->networks->add_route(100,
        destination => '10.200.0.0/16',
        gateway     => '10.0.0.1',
    );
    is($result->{action}{command}, 'add_route', 'action command');
};

subtest 'delete route' => sub {
    my $fixture = load_fixture('networks_action');
    $fixture->{action}{command} = 'delete_route';

    my $cloud = mock_cloud(
        'POST /networks/100/actions/delete_route' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{destination}, '10.200.0.0/16', 'destination in request');
            is($opts{body}{gateway}, '10.0.0.1', 'gateway in request');
            return $fixture;
        },
    );

    my $result = $cloud->networks->delete_route(100,
        destination => '10.200.0.0/16',
        gateway     => '10.0.0.1',
    );
    is($result->{action}{command}, 'delete_route', 'action command');
};

subtest 'network entity methods' => sub {
    my $fixture = load_fixture('networks_get');

    my $cloud = mock_cloud(
        '/networks/100' => $fixture,
    );

    my $network = $cloud->networks->get(100);

    my $data = $network->data;
    is($data->{id}, 100, 'data id');
    is($data->{name}, 'my-network', 'data name');
    is($data->{ip_range}, '10.0.0.0/8', 'data ip_range');
};

done_testing;
