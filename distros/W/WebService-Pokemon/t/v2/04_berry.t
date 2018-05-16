use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($poke_api, $got);

$poke_api = WebService::Pokemon->new;

$got = $poke_api->berry(id => 1);
is($got->{name}, 'cheri', 'expect berry found by id');

$got = $poke_api->berry(id => 9999999999);
is($got, undef, 'expect berry not found');

$got = $poke_api->berry(id => 'cheri');
is($got->{name}, 'cheri', 'expect berry found by name');

my ($result_a, $result_b);

$got = $poke_api->berries();
$result_a = $got->{results};

$got = $poke_api->berries(limit => 20, offset => 0);
$result_b = $got->{results};

is_deeply($result_a, $result_b, 'expect default options set');

done_testing;
