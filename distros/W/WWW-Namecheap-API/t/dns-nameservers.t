#!perl -T

use Test::More;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

plan tests => 12;

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $domains = $api->domain->list;
isa_ok($domains, 'ARRAY');

my $domindex = rand(scalar(@$domains));

my $name = $domains->[$domindex]->{Name};

my $nsarray = [
    'udns1.ultradns.net',
    'udns2.ultradns.net',
];

my $theirnsarray = [
    'dns1.registrar-servers.com',
    'dns2.registrar-servers.com',
    'dns3.registrar-servers.com',
];

my $result = $api->dns->setnameservers(DomainName => $name, Nameservers => $nsarray);
is($result->{Domain}, $name);
is($result->{Updated}, 'true');

my $nscheck = $api->dns->getnameservers(DomainName => $name);
is($nscheck->{Domain}, $name);
is($nscheck->{IsUsingOurDNS}, 'false');
is_deeply($nscheck->{Nameserver}, $nsarray);

my $result2 = $api->dns->setnameservers(DomainName => $name, DefaultNS => 1);
is($result2->{Domain}, $name);
is($result2->{Updated}, 'true');

my $nscheck2 = $api->dns->getnameservers(DomainName => $name);
is($nscheck2->{Domain}, $name);
is($nscheck2->{IsUsingOurDNS}, 'true');
is_deeply($nscheck2->{Nameserver}, $theirnsarray);

#use Data::Dumper;
#print STDERR Data::Dumper::Dumper \$nscheck2;
