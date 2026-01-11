use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_list = load_fixture('robot_ips_list');
my $fixture_get  = load_fixture('robot_ips_get');

my $robot = mock_robot(
    'GET /ip'        => $fixture_list,
    '/ip/[\d\.]+'    => $fixture_get,
);

subtest 'list ips' => sub {
    my $ips = $robot->ips->list;
    is(ref($ips), 'ARRAY', 'Returns arrayref');
    is(scalar(@$ips), 2, 'Has 2 IPs');

    my $ip = $ips->[0];
    is($ip->ip, '203.0.113.50', 'ip');
    is($ip->server_number, 123456, 'server_number');
    is($ip->server_ip, '203.0.113.50', 'server_ip');
    ok(!$ip->locked, 'not locked');
    ok($ip->traffic_warnings, 'traffic_warnings enabled');
    is($ip->traffic_hourly, 100, 'traffic_hourly');
    is($ip->traffic_daily, 1000, 'traffic_daily');
    is($ip->traffic_monthly, 30000, 'traffic_monthly');
};

subtest 'get ip' => sub {
    my $ip = $robot->ips->get('203.0.113.50');
    isa_ok($ip, 'WWW::Hetzner::Robot::IP');
    is($ip->ip, '203.0.113.50', 'ip');
    is($ip->server_number, 123456, 'server_number');
};

done_testing;
