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

my ($got, $ip) = ('', '1.1.1.1');
my $geoipify = WebService::GeoIPify->new(api_key => $ENV{GEOIPIFY_ACCESS_KEY});

$got = $geoipify->cache->get($ip);
is($got, undef, 'expect IP address not cached');

$got = $geoipify->lookup($ip);
$got = $geoipify->cache->get($ip);
is($got->{ip}, '1.1.1.1', 'expect IP address cached');

done_testing;
