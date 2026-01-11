#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list load balancers' => sub {
    my $fixture = load_fixture('load_balancers_list');

    my $cloud = mock_cloud(
        'GET /load_balancers' => $fixture,
    );

    my $lbs = $cloud->load_balancers->list;

    is(ref $lbs, 'ARRAY', 'returns array');
    is(scalar @$lbs, 1, 'one load balancer');
    isa_ok($lbs->[0], 'WWW::Hetzner::Cloud::LoadBalancer');
    is($lbs->[0]->id, 900, 'load balancer id');
    is($lbs->[0]->name, 'web-lb', 'load balancer name');
    is($lbs->[0]->ipv4, '203.0.113.90', 'IPv4');
    is($lbs->[0]->location_name, 'fsn1', 'location');
    is($lbs->[0]->type_name, 'lb11', 'type');
};

subtest 'get load balancer' => sub {
    my $fixture = load_fixture('load_balancers_get');

    my $cloud = mock_cloud(
        '/load_balancers/900' => $fixture,
    );

    my $lb = $cloud->load_balancers->get(900);

    isa_ok($lb, 'WWW::Hetzner::Cloud::LoadBalancer');
    is($lb->id, 900, 'load balancer id');
    is($lb->algorithm->{type}, 'round_robin', 'algorithm');
    is(scalar @{$lb->targets}, 1, 'one target');
    is(scalar @{$lb->services}, 1, 'one service');
};

subtest 'create load balancer' => sub {
    my $fixture = load_fixture('load_balancers_create');

    my $cloud = mock_cloud(
        'POST /load_balancers' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'new-lb', 'name in request');
            is($body->{load_balancer_type}, 'lb11', 'type in request');
            is($body->{location}, 'fsn1', 'location in request');

            return $fixture;
        },
    );

    my $lb = $cloud->load_balancers->create(
        name               => 'new-lb',
        load_balancer_type => 'lb11',
        location           => 'fsn1',
    );

    isa_ok($lb, 'WWW::Hetzner::Cloud::LoadBalancer');
    is($lb->id, 1000, 'new load balancer id');
};

subtest 'delete load balancer' => sub {
    my $cloud = mock_cloud(
        'DELETE /load_balancers/900' => {},
    );

    my $result = $cloud->load_balancers->delete(900);
    ok(1, 'delete succeeded');
};

subtest 'create load balancer requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->load_balancers->create() };
    like($@, qr/name required/, 'name required');

    eval { $cloud->load_balancers->create(name => 'test') };
    like($@, qr/load_balancer_type required/, 'type required');

    eval { $cloud->load_balancers->create(name => 'test', load_balancer_type => 'lb11') };
    like($@, qr/location required/, 'location required');
};

subtest 'add target' => sub {
    my $fixture = load_fixture('load_balancers_action');

    my $cloud = mock_cloud(
        'POST /load_balancers/900/actions/add_target' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{type}, 'server', 'type in request');
            is($opts{body}{server}{id}, 456, 'server id in request');
            return $fixture;
        },
    );

    my $result = $cloud->load_balancers->add_target(900,
        type   => 'server',
        server => { id => 456 },
    );
    is($result->{action}{command}, 'add_target', 'action command');
};

subtest 'add service' => sub {
    my $fixture = load_fixture('load_balancers_action');
    $fixture->{action}{command} = 'add_service';

    my $cloud = mock_cloud(
        'POST /load_balancers/900/actions/add_service' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{protocol}, 'https', 'protocol in request');
            is($opts{body}{listen_port}, 443, 'listen_port in request');
            return $fixture;
        },
    );

    my $result = $cloud->load_balancers->add_service(900,
        protocol         => 'https',
        listen_port      => 443,
        destination_port => 8443,
    );
    is($result->{action}{command}, 'add_service', 'action command');
};

done_testing;
