use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_get     = load_fixture('robot_reset_get');
my $fixture_execute = load_fixture('robot_reset_execute');
my $fixture_wol     = load_fixture('robot_wol');

my $robot = mock_robot(
    'GET /reset/123456'  => $fixture_get,
    'POST /reset/123456' => $fixture_execute,
    'POST /wol/123456'   => $fixture_wol,
);

subtest 'get reset info' => sub {
    my $info = $robot->reset->get(123456);
    is($info->{server_number}, 123456, 'server_number');
    is_deeply($info->{type}, ['sw', 'hw', 'man'], 'reset types available');
};

subtest 'execute reset' => sub {
    my $result = $robot->reset->execute(123456, 'sw');
    is($result->{server_number}, 123456, 'server_number');
    is($result->{type}, 'sw', 'reset type');
};

subtest 'convenience methods' => sub {
    my $result = $robot->reset->software(123456);
    is($result->{type}, 'sw', 'software reset');
};

subtest 'wake-on-lan' => sub {
    my $result = $robot->reset->wol(123456);
    is($result->{server_number}, 123456, 'WOL sent');
};

done_testing;
