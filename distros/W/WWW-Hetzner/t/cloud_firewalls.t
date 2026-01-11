#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list firewalls' => sub {
    my $fixture = load_fixture('firewalls_list');

    my $cloud = mock_cloud(
        'GET /firewalls' => $fixture,
    );

    my $firewalls = $cloud->firewalls->list;

    is(ref $firewalls, 'ARRAY', 'returns array');
    is(scalar @$firewalls, 1, 'one firewall');
    isa_ok($firewalls->[0], 'WWW::Hetzner::Cloud::Firewall');
    is($firewalls->[0]->id, 300, 'firewall id');
    is($firewalls->[0]->name, 'web-firewall', 'firewall name');
    is(scalar @{$firewalls->[0]->rules}, 2, 'two rules');
    is(scalar @{$firewalls->[0]->applied_to}, 1, 'applied to one resource');
};

subtest 'get firewall' => sub {
    my $fixture = load_fixture('firewalls_get');

    my $cloud = mock_cloud(
        '/firewalls/300' => $fixture,
    );

    my $fw = $cloud->firewalls->get(300);

    isa_ok($fw, 'WWW::Hetzner::Cloud::Firewall');
    is($fw->id, 300, 'firewall id');
    is($fw->name, 'web-firewall', 'firewall name');
    is($fw->rules->[0]{direction}, 'in', 'first rule direction');
    is($fw->rules->[0]{port}, '22', 'first rule port');
};

subtest 'create firewall' => sub {
    my $fixture = load_fixture('firewalls_create');

    my $cloud = mock_cloud(
        'POST /firewalls' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'new-firewall', 'name in request');

            return $fixture;
        },
    );

    my $fw = $cloud->firewalls->create(
        name => 'new-firewall',
    );

    isa_ok($fw, 'WWW::Hetzner::Cloud::Firewall');
    is($fw->id, 400, 'new firewall id');
    is($fw->name, 'new-firewall', 'new firewall name');
};

subtest 'delete firewall' => sub {
    my $cloud = mock_cloud(
        'DELETE /firewalls/300' => {},
    );

    my $result = $cloud->firewalls->delete(300);
    ok(1, 'delete succeeded');
};

subtest 'create firewall requires name' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->firewalls->create() };
    like($@, qr/name required/, 'name required');
};

subtest 'set rules' => sub {
    my $fixture = load_fixture('firewalls_action');

    my $cloud = mock_cloud(
        'POST /firewalls/300/actions/set_rules' => sub {
            my ($method, $path, %opts) = @_;
            is(scalar @{$opts{body}{rules}}, 1, 'one rule in request');
            is($opts{body}{rules}[0]{port}, '443', 'port in rule');
            return $fixture;
        },
    );

    my $result = $cloud->firewalls->set_rules(300, [
        { direction => 'in', protocol => 'tcp', port => '443', source_ips => ['0.0.0.0/0'] },
    ]);
    is($result->{actions}[0]{command}, 'set_firewall_rules', 'action command');
};

subtest 'apply to resources' => sub {
    my $fixture = load_fixture('firewalls_action');
    $fixture->{actions}[0]{command} = 'apply_to_resources';

    my $cloud = mock_cloud(
        'POST /firewalls/300/actions/apply_to_resources' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{apply_to}[0]{type}, 'server', 'type in request');
            is($opts{body}{apply_to}[0]{server}{id}, 456, 'server id in request');
            return $fixture;
        },
    );

    my $result = $cloud->firewalls->apply_to_resources(300,
        { type => 'server', server => { id => 456 } },
    );
    is($result->{actions}[0]{command}, 'apply_to_resources', 'action command');
};

subtest 'remove from resources' => sub {
    my $fixture = load_fixture('firewalls_action');
    $fixture->{actions}[0]{command} = 'remove_from_resources';

    my $cloud = mock_cloud(
        'POST /firewalls/300/actions/remove_from_resources' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{remove_from}[0]{type}, 'server', 'type in request');
            return $fixture;
        },
    );

    my $result = $cloud->firewalls->remove_from_resources(300,
        { type => 'server', server => { id => 456 } },
    );
    is($result->{actions}[0]{command}, 'remove_from_resources', 'action command');
};

subtest 'firewall entity methods' => sub {
    my $fixture = load_fixture('firewalls_get');

    my $cloud = mock_cloud(
        '/firewalls/300' => $fixture,
    );

    my $fw = $cloud->firewalls->get(300);

    my $data = $fw->data;
    is($data->{id}, 300, 'data id');
    is($data->{name}, 'web-firewall', 'data name');
    is(scalar @{$data->{rules}}, 2, 'data rules count');
};

done_testing;
