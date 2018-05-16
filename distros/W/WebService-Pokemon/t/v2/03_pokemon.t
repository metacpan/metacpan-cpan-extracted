use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($poke_api, $got);

$poke_api = WebService::Pokemon->new;

$got = $poke_api->pokemon(id => 1);
is($got->{name}, 'bulbasaur', 'expect pokemon found');

$got = $poke_api->pokemon(id => 9999999999);
is($got, undef, 'expect pokemon not found');

my ($result_a, $result_b);

$got = $poke_api->pokemons();
$result_a = $got->{results};

$got = $poke_api->pokemons(limit => 20, offset => 0);
$result_b = $got->{results};

is_deeply($result_a, $result_b, 'expect default options set');

done_testing;
