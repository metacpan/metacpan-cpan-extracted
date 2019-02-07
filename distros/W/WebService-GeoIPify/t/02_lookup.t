use strict;
use utf8;
use warnings;

use Test::Exception;
use Test::More;

use WebService::GeoIPify;

BEGIN {
    unless ($ENV{GEOIPIFY_ACCESS_KEY}) {
        plan skip_all => '$ENV{GEOIPIFY_ACCESS_KEY} not set, skipping live tests'
    }
}

my $got;
my $geoipify = WebService::GeoIPify->new(api_key => $ENV{GEOIPIFY_ACCESS_KEY});

$got = $geoipify->lookup('8.8.8.8');
is($got->{ip}, '8.8.8.8', 'expect IP address match');
is($got->{location}->{country}, 'US', 'expect country code match');

foreach my $ip (qw(10.8.8.8 127.0.0.1 0:0:0:0:0:ffff:808:808)) {
    dies_ok {
        $got = $geoipify->lookup($ip);
    } 'expect exception on non-IPv4 address';
}

done_testing;
