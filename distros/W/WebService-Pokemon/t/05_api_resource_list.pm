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

my ($got, $expect, $url) = ('', '', '');

my $api = WebService::Pokemon->new;

$got = $api->resource('berry');
is(scalar %{$got->results->[0]}, 2, 'expect no autoload of each results items');

$api->autoload(1);
$got = $api->resource('berry');
is(scalar %{$got->results->[0]}, 14, 'expect autoload of each results item');

done_testing;
