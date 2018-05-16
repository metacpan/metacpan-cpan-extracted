use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($pokemon, $got);

$pokemon = WebService::Pokemon->new;

$got = $pokemon->api_version;
is($got, 'v2', 'expect default API version match');

$pokemon = WebService::Pokemon->new(api_version => 'v1');
$got = $pokemon->api_version;
is($got, 'v1', 'expect initiated API version through constructor match');

$got = $pokemon->api_version('v2');
is($got, 'v2', 'expect set API version through method match');

done_testing;
