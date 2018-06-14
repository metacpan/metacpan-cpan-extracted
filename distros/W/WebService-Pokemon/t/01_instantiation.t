use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my $api;

$api = WebService::Pokemon->new;
is(ref $api, 'WebService::Pokemon', 'expect object instantiate through new');
is($api->api_url, 'https://pokeapi.co/api/v2', 'expect API URL match');

$api = WebService::Pokemon->new(api_url => 'http://localhost/api/v2');
is($api->api_url, 'http://localhost/api/v2', 'expect new API URL match');

my $cacher = CHI->new(
    driver => 'File',
    namespace => 'restcountries',
    root_dir => $ENV{PWD} . '/t/cache/',
);
$api->cache($cacher);
is($api->cache->root_dir, $ENV{PWD} . '/t/cache/', 'expect cache engine set correctly');

done_testing;
