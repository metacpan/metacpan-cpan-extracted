use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($poke_api, $got);

$poke_api = WebService::Pokemon->new;

$got = $poke_api->berry_flavor(id => 1);
is($got->{name}, 'spicy', 'expect berry flavor found by id');

$got = $poke_api->berry_flavor(id => 9999999999);
is($got, undef, 'expect berry flavor not found');

$got = $poke_api->berry_flavor(id => 'spicy');
is($got->{name}, 'spicy', 'expect berry flavor found by name');

done_testing;
