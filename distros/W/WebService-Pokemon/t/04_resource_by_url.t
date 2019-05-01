use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

BEGIN {
    unless ($ENV{SWAPI_LIVE}) {
        plan skip_all => '$ENV{SWAPI_LIVE} not set, skipping live tests'
    }
}

my ($got, $expect, $url) = ('', '', '');

my $api = WebService::Pokemon->new;

$url = 'https://pokeapi.co/api/v2/berry/?limit=20&offset=20';
$got = $api->resource_by_url($url);
is(ref $got, 'WebService::Pokemon::APIResourceList', 'expect class type');
is($got->count, 64, 'expect resource count tally');
is($got->previous, 'https://pokeapi.co/api/v2/berry?offset=0&limit=20', 'expect previous URL found');
is($got->next, 'https://pokeapi.co/api/v2/berry?offset=40&limit=20', 'expect next URL found');

$url = 'https://pokeapi.co/api/v2/berry/1';
$got = $api->resource_by_url($url);
is(ref $got, 'WebService::Pokemon::NamedAPIResource', 'expect data class type');
is(ref $got->api, 'WebService::Pokemon', 'expect api class type');
is($got->{name}, 'cheri', 'expect resource name match');

done_testing;
