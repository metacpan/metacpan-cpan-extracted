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
    isa_ok($server->action, 'WWW::Hetzner::Action', 'create action is an Action');
    is($server->action->command, 'create_server', 'action command');
    is(scalar @{ $server->next_actions }, 1, 'next_actions populated');
};

subtest 'delete server' => sub {
    # karr #7: DELETE /servers/{id} answers 200 {action}; the action used to be
    # dropped, so the caller could not wait for the deletion to finish.
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'delete_server';

    my $cloud = mock_cloud(
        'DELETE /servers/123456' => $fixture,
    );

    my $action = $cloud->servers->delete(123456);
    isa_ok($action, 'WWW::Hetzner::Action', 'delete returns an Action');
    is($action->id, 13343, 'delete action id');
    is($action->command, 'delete_server', 'delete action command');
    ok($action->is_running, 'delete action is still running');
};

subtest 'delete server via entity mirror' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'delete_server';

    my $cloud = mock_cloud(
        'GET /servers/123456'    => sub { load_fixture('servers_get') },
        'DELETE /servers/123456' => $fixture,
    );

    my $server = $cloud->servers->get(123456);
    my $action = $server->delete;
    isa_ok($action, 'WWW::Hetzner::Action', '$server->delete returns an Action');
    is($action->command, 'delete_server', 'entity mirror carries the action command');
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
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'poweron', 'action command');
};

subtest 'power_off' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'poweroff';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/poweroff' => $fixture,
    );

    my $result = $cloud->servers->power_off(123456);
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'poweroff', 'action command');
};

subtest 'reboot' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'reboot';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/reboot' => $fixture,
    );

    my $result = $cloud->servers->reboot(123456);
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'reboot', 'action command');
};

subtest 'shutdown' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'shutdown';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/shutdown' => $fixture,
    );

    my $result = $cloud->servers->shutdown(123456);
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'shutdown', 'action command');
};

subtest 'rebuild' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'rebuild';
    $fixture->{root_password} = 'the-generated-pw';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/rebuild' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{image}, 'debian-13', 'image in request');
            return $fixture;
        },
    );

    my $result = $cloud->servers->rebuild(123456, 'debian-13');
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'rebuild', 'action command');
    is($result->root_password, 'the-generated-pw', 'root_password preserved on the Action');
    is($result->result->{root_password}, 'the-generated-pw', 'result carries sidecar');
};

subtest 'enable_rescue' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'enable_rescue';
    $fixture->{root_password} = 'rescue-pw';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/enable_rescue' => $fixture,
    );

    my $result = $cloud->servers->enable_rescue(123456);
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'enable_rescue', 'action command');
    is($result->root_password, 'rescue-pw', 'root_password preserved on the Action');
    is($result->result->{root_password}, 'rescue-pw', 'result carries sidecar');
};

subtest 'reset_password' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'reset_password';
    $fixture->{root_password} = 'the-generated-pw';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/reset_password' => $fixture,
    );

    my $action = $cloud->servers->reset_password(123456);
    isa_ok($action, 'WWW::Hetzner::Action');
    is($action->root_password, 'the-generated-pw', 'root_password preserved on the Action');
    is($action->result->{root_password}, 'the-generated-pw', 'result carries sidecar');
};

subtest 'request_console' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'request_console';
    $fixture->{password} = 'console-pw';
    $fixture->{wss_url}  = 'wss://console.hetzner.cloud/?token=abc123';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/request_console' => $fixture,
    );

    my $result = $cloud->servers->request_console(123456);
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'request_console', 'action command');
    is($result->password, 'console-pw', 'password preserved on the Action');
    is($result->wss_url, 'wss://console.hetzner.cloud/?token=abc123', 'wss_url preserved on the Action');
    is_deeply($result->result, {
        password => 'console-pw',
        wss_url  => 'wss://console.hetzner.cloud/?token=abc123',
    }, 'result carries both sidecar fields');
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
    isa_ok($result, 'WWW::Hetzner::Action');
    is($result->command, 'change_type', 'action command');
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

subtest 'server entity action methods return Action' => sub {
    my $get_fixture = load_fixture('servers_get');

    my $cloud = mock_cloud(
        '/servers/123456' => $get_fixture,
        'POST /servers/123456/actions/poweron' => sub {
            my $f = load_fixture('servers_action');
            $f->{action}{command} = 'poweron';
            return $f;
        },
        'POST /servers/123456/actions/poweroff' => sub {
            my $f = load_fixture('servers_action');
            $f->{action}{command} = 'poweroff';
            return $f;
        },
        'POST /servers/123456/actions/reboot' => sub {
            my $f = load_fixture('servers_action');
            $f->{action}{command} = 'reboot';
            return $f;
        },
        'POST /servers/123456/actions/shutdown' => sub {
            my $f = load_fixture('servers_action');
            $f->{action}{command} = 'shutdown';
            return $f;
        },
        'POST /servers/123456/actions/rebuild' => sub {
            my $f = load_fixture('servers_action');
            $f->{action}{command} = 'rebuild';
            return $f;
        },
    );

    my $server = $cloud->servers->get(123456);

    isa_ok($server->power_on, 'WWW::Hetzner::Action', 'entity power_on returns Action');
    isa_ok($server->power_off, 'WWW::Hetzner::Action', 'entity power_off returns Action');
    isa_ok($server->reboot, 'WWW::Hetzner::Action', 'entity reboot returns Action');
    isa_ok($server->shutdown, 'WWW::Hetzner::Action', 'entity shutdown returns Action');
    isa_ok($server->rebuild('debian-13'), 'WWW::Hetzner::Action', 'entity rebuild returns Action');
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
