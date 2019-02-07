use strict;
use utf8;
use warnings;

use Test::Exception;
use Test::More;

use WebService::GeoIPify;

my ($geoipify, $api_key) = ('', '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');

$geoipify = WebService::GeoIPify->new(api_key => $api_key);
is($geoipify->api_url, 'https://geo.ipify.org/api/v1', 'expect API URL match');
is($geoipify->api_key, $api_key, 'expect api key match');

dies_ok {
    $geoipify = WebService::GeoIPify->new(api_key => 'foobar');
} 'expect exception on invalid API key length';

dies_ok {
    $geoipify = WebService::GeoIPify->new();
} 'expect exception on missing argument: api_key';

done_testing;
