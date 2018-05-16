use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($poke_api, $got);

$poke_api = WebService::Pokemon->new;

$got = $poke_api->berry_firmness(id => 1);
is($got->{name}, 'very-soft', 'expect berry firmness found by id');

$got = $poke_api->berry_firmness(id => 9999999999);
is($got, undef, 'expect berry firmness not found');

$got = $poke_api->berry_firmness(id => 'very-soft');
is($got->{name}, 'very-soft', 'expect berry firmness found by name');

done_testing;
