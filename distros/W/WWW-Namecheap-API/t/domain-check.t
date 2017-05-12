#!perl -T

use Test::More;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

plan tests => 2;

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $expected_result = {
    'example.com' => 0,
    'asdfaskqwjqkfjaslfkeia.com' => 1,
    'thisisalongbadfaketestdomain.com' => 1,
    'wwwnamecheapapi50602.com' => 0,
};

is_deeply($api->domain->check(Domains => [keys %$expected_result]), $expected_result);
