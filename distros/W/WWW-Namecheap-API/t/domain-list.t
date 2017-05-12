#!perl -T

use Test::More;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $domains = $api->domain->list;
isa_ok($domains, 'ARRAY');
my $onedomain = $api->domain->list(SearchTerm => 'wwwnamecheapapi38449.com');
isa_ok($onedomain, 'ARRAY');

my $tests = 3;

foreach my $dom (@$domains, @$onedomain) {
    like($dom->{ID}, qr/^\d+$/);
    like($dom->{Name}, qr/^[\w.-]+$/);
    is($dom->{User}, 'wwwnamecheapapi');
    like($dom->{Created}, qr{^\d{2}/\d{2}/\d{4}$});
    like($dom->{Expires}, qr{^\d{2}/\d{2}/\d{4}$});
    $tests += 5;
}

done_testing($tests);
