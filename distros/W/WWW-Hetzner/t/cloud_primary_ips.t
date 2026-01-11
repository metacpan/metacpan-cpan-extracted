#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list primary IPs' => sub {
    my $fixture = load_fixture('primary_ips_list');

    my $cloud = mock_cloud(
        'GET /primary_ips' => $fixture,
    );

    my $pips = $cloud->primary_ips->list;

    is(ref $pips, 'ARRAY', 'returns array');
    is(scalar @$pips, 1, 'one primary IP');
    isa_ok($pips->[0], 'WWW::Hetzner::Cloud::PrimaryIP');
    is($pips->[0]->id, 700, 'primary IP id');
    is($pips->[0]->name, 'server-ip', 'primary IP name');
    is($pips->[0]->ip, '203.0.113.70', 'IP address');
    is($pips->[0]->type, 'ipv4', 'IP type');
    is($pips->[0]->assignee_id, 123, 'assigned to server');
    ok($pips->[0]->is_assigned, 'is_assigned returns true');
    is($pips->[0]->datacenter_name, 'fsn1-dc14', 'datacenter');
};

subtest 'get primary IP' => sub {
    my $fixture = load_fixture('primary_ips_get');

    my $cloud = mock_cloud(
        '/primary_ips/700' => $fixture,
    );

    my $pip = $cloud->primary_ips->get(700);

    isa_ok($pip, 'WWW::Hetzner::Cloud::PrimaryIP');
    is($pip->id, 700, 'primary IP id');
    is($pip->auto_delete, 1, 'auto_delete');
    is($pip->dns_ptr->[0]{dns_ptr}, 'server.example.com', 'dns_ptr');
};

subtest 'create primary IP' => sub {
    my $fixture = load_fixture('primary_ips_create');

    my $cloud = mock_cloud(
        'POST /primary_ips' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'new-primary-ip', 'name in request');
            is($body->{type}, 'ipv4', 'type in request');
            is($body->{datacenter}, 'fsn1-dc14', 'datacenter in request');
            is($body->{assignee_type}, 'server', 'assignee_type in request');

            return $fixture;
        },
    );

    my $pip = $cloud->primary_ips->create(
        name          => 'new-primary-ip',
        type          => 'ipv4',
        datacenter    => 'fsn1-dc14',
        assignee_type => 'server',
    );

    isa_ok($pip, 'WWW::Hetzner::Cloud::PrimaryIP');
    is($pip->id, 800, 'new primary IP id');
    is($pip->ip, '203.0.113.80', 'new IP address');
    ok(!$pip->is_assigned, 'not assigned');
};

subtest 'delete primary IP' => sub {
    my $cloud = mock_cloud(
        'DELETE /primary_ips/700' => {},
    );

    my $result = $cloud->primary_ips->delete(700);
    ok(1, 'delete succeeded');
};

subtest 'create primary IP requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->primary_ips->create() };
    like($@, qr/name required/, 'name required');

    eval { $cloud->primary_ips->create(name => 'test') };
    like($@, qr/type required/, 'type required');

    eval { $cloud->primary_ips->create(name => 'test', type => 'ipv4') };
    like($@, qr/assignee_type required/, 'assignee_type required');

    eval { $cloud->primary_ips->create(name => 'test', type => 'ipv4', assignee_type => 'server') };
    like($@, qr/datacenter required/, 'datacenter required');
};

subtest 'assign primary IP' => sub {
    my $fixture = load_fixture('primary_ips_action');

    my $cloud = mock_cloud(
        'POST /primary_ips/700/actions/assign' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{assignee_id}, 456, 'assignee_id in request');
            is($opts{body}{assignee_type}, 'server', 'assignee_type in request');
            return $fixture;
        },
    );

    my $result = $cloud->primary_ips->assign(700, 456, 'server');
    is($result->{action}{command}, 'assign_primary_ip', 'action command');
};

subtest 'unassign primary IP' => sub {
    my $fixture = load_fixture('primary_ips_action');
    $fixture->{action}{command} = 'unassign_primary_ip';

    my $cloud = mock_cloud(
        'POST /primary_ips/700/actions/unassign' => $fixture,
    );

    my $result = $cloud->primary_ips->unassign(700);
    is($result->{action}{command}, 'unassign_primary_ip', 'action command');
};

subtest 'primary IP entity methods' => sub {
    my $fixture = load_fixture('primary_ips_get');

    my $cloud = mock_cloud(
        '/primary_ips/700' => $fixture,
    );

    my $pip = $cloud->primary_ips->get(700);

    my $data = $pip->data;
    is($data->{id}, 700, 'data id');
    is($data->{ip}, '203.0.113.70', 'data ip');
    is($data->{type}, 'ipv4', 'data type');
};

done_testing;
