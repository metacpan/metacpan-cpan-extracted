use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_list = load_fixture('robot_servers_list');
my $fixture_get  = load_fixture('robot_servers_get');

my $robot = mock_robot(
    'GET /server'        => $fixture_list,
    '/server/\d+'        => $fixture_get,
);

subtest 'list servers' => sub {
    my $servers = $robot->servers->list;
    is(ref($servers), 'ARRAY', 'Returns arrayref');
    is(scalar(@$servers), 2, 'Has 2 servers');

    my $s = $servers->[0];
    is($s->server_number, 123456, 'server_number');
    is($s->server_name, 'omnicorp-dedicated-1', 'server_name');
    is($s->server_ip, '203.0.113.50', 'server_ip');
    is($s->product, 'AX41-NVMe', 'product');
    is($s->dc, 'FSN1-DC14', 'dc');
    is($s->status, 'ready', 'status');
    ok(!$s->cancelled, 'not cancelled');
};

subtest 'get server' => sub {
    my $server = $robot->servers->get(123456);
    isa_ok($server, 'WWW::Hetzner::Robot::Server');
    is($server->server_number, 123456, 'server_number');
    is($server->server_name, 'omnicorp-dedicated-1', 'server_name');
    is($server->product, 'AX41-NVMe', 'product');

    # Convenience accessors
    is($server->id, 123456, 'id alias');
    is($server->name, 'omnicorp-dedicated-1', 'name alias');
    is($server->ip, '203.0.113.50', 'ip alias');
};

done_testing;
