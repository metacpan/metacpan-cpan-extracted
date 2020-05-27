use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use WebService::KvKAPI;
use Sub::Override;
use Test::Mock::One;
use Test::Deep;

my $api = WebService::KvKAPI->new(
    api_key  => 'foobar',
);

my $params = { kvkNumber => 8, branchNumber => 12 };

$api->mangle_params($params);

cmp_deeply(
    $params,
    { kvkNumber => '00000008', branchNumber => '000000000012' },
    "Mangling works"
);

done_testing;
