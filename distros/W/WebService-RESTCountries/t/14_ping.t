use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my $got;

my $api = WebService::RESTCountries->new;

$got = $api->ping();
is($got, 1, 'expect API endpoint is up');

$api->api_url('http://foobar.localhost');
$got = $api->ping();
is($got, 0, 'expect API endpoint is down');


done_testing;
