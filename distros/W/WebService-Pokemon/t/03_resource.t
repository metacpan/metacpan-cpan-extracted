use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

BEGIN {
    unless ($ENV{POKEAPI_LIVE}) {
        plan skip_all => '$ENV{POKEAPI_LIVE} not set, skipping live tests'
    }
}

my $got;

my $api = WebService::Pokemon->new;

$got = $api->resource('berry');
is(ref $got, 'WebService::Pokemon::APIResourceList', 'expect class type');
is($got->previous, undef, 'expect previous URL not found');
is($got->count, 64, 'expect resource count tally');
is($got->next, 'https://pokeapi.co/api/v2/berry?offset=20&limit=20', 'expect next URL found');

$api->autoload(1);
$got = $api->resource('berry');
is($got->count, 64, 'expect resource count tally for second call');

done_testing;
