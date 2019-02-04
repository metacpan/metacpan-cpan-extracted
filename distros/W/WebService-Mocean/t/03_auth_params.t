use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Mocean;

my ($got, $expect) = ('', '');

my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

$expect = {
    'mocean-api-key' => 'foo',
    'mocean-api-secret' => 'bar',
};
$got = $mocean_api->client->_auth_params();
is_deeply($got, $expect, 'expect auth params match');

done_testing;
