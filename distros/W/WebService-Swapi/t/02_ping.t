use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Swapi;

my $swapi = WebService::Swapi->new();
my $response;

$response = $swapi->ping();
is($response, 1, "expect api resource: " . $swapi->api_url . " is up");

$swapi->api_url('http://localhost/api/');

$response = $swapi->ping();
is($response, 0, "expect api resource: " . $swapi->api_url . " is down");

done_testing;
