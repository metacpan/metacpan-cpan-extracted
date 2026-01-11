#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list servers' => sub {
    my $fixture = load_fixture('servers_list');

    my $cloud = mock_cloud(
        'GET /servers' => $fixture,
    );

    my $servers = $cloud->servers->list;

    is(ref $servers, 'ARRAY', 'returns array');
    is(scalar @$servers, 1, 'one server');
    isa_ok($servers->[0], 'WWW::Hetzner::Cloud::Server');
    is($servers->[0]->id, 123456, 'server id');
    is($servers->[0]->name, 'omnicorp-cop', 'server name');
    is($servers->[0]->status, 'running', 'server status');
    is($servers->[0]->ipv4, '203.0.113.10', 'server ip via accessor');
    ok($servers->[0]->is_running, 'is_running returns true');
};

subtest 'list servers by label' => sub {
    my $fixture = load_fixture('servers_list');

    my $cloud = mock_cloud(
        'GET /servers' => sub {
            my ($method, $path, %opts) = @_;
            return $fixture;
        },
    );

    my $servers = $cloud->servers->list_by_label('ocp-cluster=omnicorp');

    is(scalar @$servers, 1, 'one server');
    is($servers->[0]{labels}{'ocp-cluster'}, 'omnicorp', 'label matches');
};

subtest 'get server' => sub {
    my $fixture = load_fixture('servers_get');

    my $cloud = mock_cloud(
        '/servers/123456' => $fixture,
    );

    my $server = $cloud->servers->get(123456);

    isa_ok($server, 'WWW::Hetzner::Cloud::Server');
    is($server->id, 123456, 'server id');
    is($server->name, 'omnicorp-cop', 'server name');
    is($server->status, 'running', 'server status');
};

subtest 'create server' => sub {
    my $fixture = load_fixture('servers_create');

    my $cloud = mock_cloud(
        'POST /servers' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'test-full-params', 'name in request');
            is($body->{server_type}, 'ccx13', 'server_type in request');
            is($body->{image}, 'debian-12', 'image in request');
            is($body->{location}, 'fsn1', 'location in request');

            return $fixture;
        },
    );

    my $server = $cloud->servers->create(
        name        => 'test-full-params',
        server_type => 'ccx13',
        image       => 'debian-12',
        location    => 'fsn1',
    );

    isa_ok($server, 'WWW::Hetzner::Cloud::Server');
    is($server->id, 12345678, 'new server id');
    is($server->name, 'test-full-params', 'new server name');
    is($server->status, 'initializing', 'new server status');
    ok(!$server->is_running, 'is_running returns false for initializing');
};

subtest 'delete server' => sub {
    my $cloud = mock_cloud(
        'DELETE /servers/123456' => {},
    );

    my $result = $cloud->servers->delete(123456);
    ok(1, 'delete succeeded');
};

subtest 'create server requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->servers->create() };
    like($@, qr/name required/, 'name required');

    eval { $cloud->servers->create(name => 'test') };
    like($@, qr/server_type required/, 'server_type required');

    eval { $cloud->servers->create(name => 'test', server_type => 'cx23') };
    like($@, qr/image required/, 'image required');
};

subtest 'power_on' => sub {
    my $fixture = load_fixture('servers_action');

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/poweron' => $fixture,
    );

    my $result = $cloud->servers->power_on(123456);
    is($result->{action}{command}, 'poweron', 'action command');
};

subtest 'power_off' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'poweroff';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/poweroff' => $fixture,
    );

    my $result = $cloud->servers->power_off(123456);
    is($result->{action}{command}, 'poweroff', 'action command');
};

subtest 'reboot' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'reboot';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/reboot' => $fixture,
    );

    my $result = $cloud->servers->reboot(123456);
    is($result->{action}{command}, 'reboot', 'action command');
};

subtest 'shutdown' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'shutdown';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/shutdown' => $fixture,
    );

    my $result = $cloud->servers->shutdown(123456);
    is($result->{action}{command}, 'shutdown', 'action command');
};

subtest 'rebuild' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'rebuild';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/rebuild' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{image}, 'debian-13', 'image in request');
            return $fixture;
        },
    );

    my $result = $cloud->servers->rebuild(123456, 'debian-13');
    is($result->{action}{command}, 'rebuild', 'action command');
};

subtest 'change_type' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'change_type';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/change_type' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{server_type}, 'cx33', 'server_type in request');
            return $fixture;
        },
    );

    my $result = $cloud->servers->change_type(123456, 'cx33');
    is($result->{action}{command}, 'change_type', 'action command');
};

subtest 'update server' => sub {
    my $fixture = load_fixture('servers_update');

    my $cloud = mock_cloud(
        'PUT /servers/123456' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'renamed-server', 'name in request');
            is($opts{body}{labels}{env}, 'production', 'labels in request');
            return $fixture;
        },
    );

    my $server = $cloud->servers->update(123456,
        name   => 'renamed-server',
        labels => { env => 'production' },
    );

    isa_ok($server, 'WWW::Hetzner::Cloud::Server');
    is($server->name, 'renamed-server', 'server renamed');
    is($server->labels->{env}, 'production', 'labels updated');
};

subtest 'wait_for_status' => sub {
    my $call_count = 0;
    my $fixture = load_fixture('servers_get');

    my $cloud = mock_cloud(
        '/servers/123456' => sub {
            $call_count++;
            if ($call_count < 3) {
                my $f = load_fixture('servers_get');
                $f->{server}{status} = 'initializing';
                return $f;
            }
            return $fixture;
        },
    );

    my $server = $cloud->servers->wait_for_status(123456, 'running', 10);
    isa_ok($server, 'WWW::Hetzner::Cloud::Server');
    is($server->status, 'running', 'server is running');
    ok($server->is_running, 'is_running returns true');
    is($call_count, 3, 'polled 3 times');
};

done_testing;
