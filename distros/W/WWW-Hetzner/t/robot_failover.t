use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_list = load_fixture('robot_failover_list');
my $fixture_get  = load_fixture('robot_failover_get');

my @calls;

my $robot = mock_robot(
    'GET /failover'                 => $fixture_list,
    'GET /failover/203.0.113.60'    => $fixture_get,
    'POST /failover/203.0.113.60'   => sub {
        my ($method, $path, %opts) = @_;
        push @calls, [$method, $path, $opts{body}];
        my $switched = load_fixture('robot_failover_get');
        $switched->{failover}{active_server_ip} = $opts{body}{active_server_ip};
        return $switched;
    },
    'DELETE /failover/203.0.113.60' => sub {
        my ($method, $path, %opts) = @_;
        push @calls, [$method, $path, undef];
        my $dropped = load_fixture('robot_failover_get');
        $dropped->{failover}{active_server_ip} = undef;
        return $dropped;
    },
);

subtest 'list failover ips' => sub {
    my $failovers = $robot->failover->list;
    is(ref($failovers), 'ARRAY', 'Returns arrayref');
    is(scalar(@$failovers), 2, 'Has 2 failover IPs');

    my $f = $failovers->[0];
    isa_ok($f, 'WWW::Hetzner::Robot::Failover');
    is($f->ip, '203.0.113.60', 'ip');
    is($f->netmask, '255.255.255.255', 'netmask');
    is($f->server_ip, '203.0.113.50', 'server_ip');
    is($f->server_number, 123456, 'server_number');
    is($f->active_server_ip, '203.0.113.50', 'active_server_ip');

    is($failovers->[1]->ip, '2001:db8:fff1::', 'IPv6 failover IP');
    is($failovers->[1]->server_ipv6_net, '2001:db8:111:4221::', 'server_ipv6_net');
};

subtest 'get failover ip' => sub {
    my $f = $robot->failover->get('203.0.113.60');
    isa_ok($f, 'WWW::Hetzner::Robot::Failover');
    is($f->ip, '203.0.113.60', 'ip');
    is($f->active_server_ip, '203.0.113.50', 'active_server_ip');
};

subtest 'switch routing to another server' => sub {
    @calls = ();

    my $f = $robot->failover->switch('203.0.113.60', '198.51.100.10');
    isa_ok($f, 'WWW::Hetzner::Robot::Failover');
    is($f->active_server_ip, '198.51.100.10', 'routes to the new server');

    is_deeply(\@calls, [
        ['POST', '/failover/203.0.113.60', { active_server_ip => '198.51.100.10' }],
    ], 'active_server_ip sent');
};

subtest 'delete routing' => sub {
    @calls = ();

    my $f = $robot->failover->delete('203.0.113.60');
    isa_ok($f, 'WWW::Hetzner::Robot::Failover');
    is($f->active_server_ip, undef, 'no active server after the routing was dropped');
    is($f->ip, '203.0.113.60', 'the IP itself is still there');

    is_deeply(\@calls, [['DELETE', '/failover/203.0.113.60', undef]], 'DELETE issued');
};

subtest 'entity switches through the client and refreshes itself' => sub {
    @calls = ();

    my $f = $robot->failover->get('203.0.113.60');
    is($f->active_server_ip, '203.0.113.50', 'starts on the original server');

    my $result = $f->switch('198.51.100.10');
    is($result->{active_server_ip}, '198.51.100.10', 'switch returns the new state');
    is($f->active_server_ip, '198.51.100.10', 'entity picked up the new active_server_ip');

    my $dropped = $f->delete;
    is($dropped->{active_server_ip}, undef, 'entity delete drops the routing');

    is_deeply(\@calls, [
        ['POST',   '/failover/203.0.113.60', { active_server_ip => '198.51.100.10' }],
        ['DELETE', '/failover/203.0.113.60', undef],
    ], 'entity calls hit the same endpoints as the controller');
};

subtest 'required parameters are enforced' => sub {
    like(exception(sub { $robot->failover->get() }), qr/Failover IP required/, 'get without ip');
    like(exception(sub { $robot->failover->switch('203.0.113.60') }),
        qr/Target server IP required/, 'switch without target');
    like(exception(sub { $robot->failover->delete() }), qr/Failover IP required/, 'delete without ip');
};

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

done_testing;
