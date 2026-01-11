use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_list = load_fixture('robot_keys_list');

my $robot = mock_robot(
    'GET /key' => $fixture_list,
);

subtest 'list keys' => sub {
    my $keys = $robot->keys->list;
    is(ref($keys), 'ARRAY', 'Returns arrayref');
    is(scalar(@$keys), 2, 'Has 2 keys');

    my $k = $keys->[0];
    is($k->name, 'omnicorp-deploy', 'name');
    is($k->fingerprint, '00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff', 'fingerprint');
    is($k->type, 'ED25519', 'type');
    is($k->size, 256, 'size');
};

done_testing;
