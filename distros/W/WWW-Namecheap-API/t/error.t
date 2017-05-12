#!perl -T

use Test::More;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

plan tests => 4;

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my %badcreate = (
    DomainName => "wwwnamecheapapi$$.com",
    Years => 1,
    Registrant => {
        OrganizationName => 'WWW-Namecheap-API',
        Address1 => '123 Fake Street',
        StateProvince => 'SD',
        PostalCode => '12345',
        Country => 'US',
        Phone => '+1.2125551212',
    },
);

my $result = $api->domain->create(%badcreate);
is($result, undef);

isa_ok($api->error, 'HASH');
is($api->error->{Errors}->{Error}->{content}, 'Parameter RegistrantFirstName is Missing');
