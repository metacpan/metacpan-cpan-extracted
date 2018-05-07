use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Swapi;

my $swapi;

$swapi = WebService::Swapi->new;
is(ref $swapi, 'WebService::Swapi', 'expect object instantiate through new');
is($swapi->api_url, 'https://swapi.co/api/', 'expect api url match');

$swapi = WebService::Swapi->new({api_url => 'https://foobar/api/'});
is($swapi->api_url, 'https://foobar/api/', 'expect api url match');

done_testing;
