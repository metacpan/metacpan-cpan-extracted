use strict;
use utf8;
use warnings;

use Test::More;

use WebService::GeoIPify;

BEGIN {
    unless ($ENV{GEOIPIFY_ACCESS_KEY}) {
        plan skip_all => '$ENV{GEOIPIFY_ACCESS_KEY} not set, skipping live tests'
    }
}

my $got;
my $geoipify = WebService::GeoIPify->new(api_key => $ENV{GEOIPIFY_ACCESS_KEY});

$got = $geoipify->check();
is(exists $got->{ip}, 1, 'expect IP address field exists');
is(exists $got->{location}, 1, 'expect location field exists');

done_testing;
