#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list floating IPs' => sub {
    my $fixture = load_fixture('floating_ips_list');

    my $cloud = mock_cloud(
        'GET /floating_ips' => $fixture,
    );

    my $fips = $cloud->floating_ips->list;

    is(ref $fips, 'ARRAY', 'returns array');
    is(scalar @$fips, 1, 'one floating IP');
    isa_ok($fips->[0], 'WWW::Hetzner::Cloud::FloatingIP');
    is($fips->[0]->id, 500, 'floating IP id');
    is($fips->[0]->name, 'web-ip', 'floating IP name');
    is($fips->[0]->ip, '203.0.113.50', 'IP address');
    is($fips->[0]->type, 'ipv4', 'IP type');
    is($fips->[0]->server, 123, 'assigned to server');
    ok($fips->[0]->is_assigned, 'is_assigned returns true');
    is($fips->[0]->location, 'fsn1', 'location');
};

subtest 'get floating IP' => sub {
    my $fixture = load_fixture('floating_ips_get');

    my $cloud = mock_cloud(
        '/floating_ips/500' => $fixture,
    );

    my $fip = $cloud->floating_ips->get(500);

    isa_ok($fip, 'WWW::Hetzner::Cloud::FloatingIP');
    is($fip->id, 500, 'floating IP id');
    is($fip->description, 'Web server IP', 'description');
    is($fip->dns_ptr->[0]{dns_ptr}, 'web.example.com', 'dns_ptr');
};

subtest 'create floating IP' => sub {
    my $fixture = load_fixture('floating_ips_create');

    my $cloud = mock_cloud(
        'POST /floating_ips' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'ipv4', 'type in request');
            is($body->{home_location}, 'fsn1', 'home_location in request');

            return $fixture;
        },
    );

    my $fip = $cloud->floating_ips->create(
        type          => 'ipv4',
        home_location => 'fsn1',
    );

    isa_ok($fip, 'WWW::Hetzner::Cloud::FloatingIP');
    is($fip->id, 600, 'new floating IP id');
    is($fip->ip, '203.0.113.60', 'new IP address');
    ok(!$fip->is_assigned, 'not assigned');
};

subtest 'delete floating IP' => sub {
    my $cloud = mock_cloud(
        'DELETE /floating_ips/500' => {},
    );

    my $result = $cloud->floating_ips->delete(500);
    ok(1, 'delete succeeded');
};

subtest 'create floating IP requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->floating_ips->create() };
    like($@, qr/type required/, 'type required');

    eval { $cloud->floating_ips->create(type => 'ipv4') };
    like($@, qr/home_location required/, 'home_location required');
};

subtest 'assign floating IP' => sub {
    my $fixture = load_fixture('floating_ips_action');

    my $cloud = mock_cloud(
        'POST /floating_ips/500/actions/assign' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{server}, 456, 'server in request');
            return $fixture;
        },
    );

    my $result = $cloud->floating_ips->assign(500, 456);
    is($result->{action}{command}, 'assign_floating_ip', 'action command');
};

subtest 'unassign floating IP' => sub {
    my $fixture = load_fixture('floating_ips_action');
    $fixture->{action}{command} = 'unassign_floating_ip';

    my $cloud = mock_cloud(
        'POST /floating_ips/500/actions/unassign' => $fixture,
    );

    my $result = $cloud->floating_ips->unassign(500);
    is($result->{action}{command}, 'unassign_floating_ip', 'action command');
};

subtest 'change dns ptr' => sub {
    my $fixture = load_fixture('floating_ips_action');
    $fixture->{action}{command} = 'change_dns_ptr';

    my $cloud = mock_cloud(
        'POST /floating_ips/500/actions/change_dns_ptr' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ip}, '203.0.113.50', 'ip in request');
            is($opts{body}{dns_ptr}, 'new.example.com', 'dns_ptr in request');
            return $fixture;
        },
    );

    my $result = $cloud->floating_ips->change_dns_ptr(500, '203.0.113.50', 'new.example.com');
    is($result->{action}{command}, 'change_dns_ptr', 'action command');
};

subtest 'floating IP entity methods' => sub {
    my $fixture = load_fixture('floating_ips_get');

    my $cloud = mock_cloud(
        '/floating_ips/500' => $fixture,
    );

    my $fip = $cloud->floating_ips->get(500);

    my $data = $fip->data;
    is($data->{id}, 500, 'data id');
    is($data->{ip}, '203.0.113.50', 'data ip');
    is($data->{type}, 'ipv4', 'data type');
};

done_testing;
