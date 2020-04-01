use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use WebService::KvKAPI;
use Sub::Override;
use Test::Mock::One;
use Test::Deep;

my $api = WebService::KvKAPI->new(
    api_key  => 'foobar',
    api_host => 'foo.bar',
);

my $client = $api->client;
isa_ok($client, "OpenAPI::Client");

is($client->base_url->host, 'foo.bar', "Base host changed to 'foo.bar'");
is($client->base_url, 'https://foo.bar/', "Base URI changed to 'foo.bar'");

done_testing;
