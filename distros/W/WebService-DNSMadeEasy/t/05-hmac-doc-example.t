use strict;
use warnings;

use Test::More;
use WebService::DNSMadeEasy;

my $dns = WebService::DNSMadeEasy->new({
    api_key => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
    secret  => 'c9b5625f-9834-4ff8-baba-4ed5f32cae55',
});

isa_ok $dns, 'WebService::DNSMadeEasy';

my %headers = $dns->client->default_headers(DateTime->new(
    year      => 2011,
    month     => 2,
    day       => 12,
    hour      => 20,
    minute    => 59,
    second    => 04,
    time_zone => 'GMT',
));

my %expected = (
    'x-dnsme-apiKey'      => '1c1a3c91-4770-4ce7-96f4-54c0eb0e457a',
    'x-dnsme-hmac'        => 'b3502e6116a324f3cf4a8ed693d78bcee8d8fe3c',
    'x-dnsme-requestDate' => 'Sat, 12 Feb 2011 20:59:04 GMT',
    'accept'              => 'application/json',
);

is_deeply \%headers, \%expected, 'request headers generated like api docs example';

done_testing;
