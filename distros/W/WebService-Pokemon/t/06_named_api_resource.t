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

my ($got, $expect) = ('', '');

my $api = WebService::Pokemon->new;

$got = $api->resource('berry', 1);
$expect = 'WebService::Pokemon::NamedAPIResource';
is(ref $got->flavors->[0], $expect, 'expect URL convert to right class');

done_testing;
