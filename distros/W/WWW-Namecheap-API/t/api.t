#!perl -T

use Test::More tests => 7;
use WWW::Namecheap::API;
use WWW::Namecheap::DNS;
use WWW::Namecheap::Domain;

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => 'fakeuser',
    ApiKey => 'fakekey',
    DefaultIp => '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $domain = $api->domain;
isa_ok($domain, 'WWW::Namecheap::Domain');
is($domain->api, $api);

my $domain2 = WWW::Namecheap::Domain->new(API => $api);
is_deeply($domain, $domain2);

my $dns = $api->dns;
isa_ok($dns, 'WWW::Namecheap::DNS');
is($dns->api, $api);

my $dns2 = WWW::Namecheap::DNS->new(API => $api);
is_deeply($dns, $dns2);
