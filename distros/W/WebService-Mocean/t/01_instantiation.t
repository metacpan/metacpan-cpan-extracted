use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;

use WebService::Mocean;

my $mocean;
my $api_key;
my $api_secret;

$mocean = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');
is($mocean->api_url, 'https://rest.moceanapi.com/rest/1', 'expect API URL match');
is($mocean->api_key, 'foo', 'expect API key URL match');
is($mocean->api_secret, 'bar', 'expect API secret URL match');

$mocean = WebService::Mocean->new({api_key => 'foo', api_secret => 'bar'});
is($mocean->api_key, 'foo', 'expect API key URL match through hash reference params');
is($mocean->api_secret, 'bar', 'expect API secret URL match through hash reference params');

done_testing;
