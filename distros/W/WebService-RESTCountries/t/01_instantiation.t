use strict;
use warnings;
use utf8;

use CHI;
use Test::More;
use Test::Warn;

use WebService::RESTCountries;

my $api;
$api = WebService::RESTCountries->new;
is($api->api_url, 'https://restcountries.eu/rest/v2/', 'expect API URL match');
is_deeply($api->fields, [], 'expect fields match');

$api = WebService::RESTCountries->new(
    api_url => 'https://example.com/rest/v2/',
    fields => ['capital', 'currencies', 'name']
);
is($api->api_url, 'https://example.com/rest/v2/', 'expect API URL match');
is_deeply($api->fields, ['capital', 'currencies', 'name'], 'expect field match');

$api->api_url('https://restcountries.eu/rest/v2/');
$api->fields([]);
is($api->api_url, 'https://restcountries.eu/rest/v2/', 'expect API URL match');
is_deeply($api->fields, [], 'expect fields match');

my $cacher = CHI->new(
    driver => 'File',
    namespace => 'restcountries',
    root_dir => $ENV{PWD} . '/t/cache/',
);
$api->cache($cacher);
is($api->cache->root_dir, $ENV{PWD} . '/t/cache/', 'expect cache engine set correctly');

done_testing;
