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

my %create = (
    DomainName => "wwwnamecheapapi$$.com",
    Years => 1,
    Registrant => {
        OrganizationName => 'WWW-Namecheap-API',
        FirstName => 'Create',
        LastName => 'Test',
        Address1 => '123 Fake Street',
        City => 'Univille',
        StateProvince => 'SD',
        PostalCode => '12345',
        Country => 'US',
        Phone => '+1.2125551212',
        EmailAddress => 'twilde@cpan.org',
    },
);

my $result = $api->domain->create(%create);
is($result->{Domain}, "wwwnamecheapapi$$.com", 'Registered domain');
is($result->{Registered}, 'true', 'Registration success');
like($result->{DomainID}, qr/^\d+$/);
like($result->{OrderID}, qr/^\d+$/);
like($result->{TransactionID}, qr/^\d+$/);
like($result->{ChargedAmount}, qr/^\d+[.]\d+$/);

my $contacts = $api->domain->getcontacts(DomainName => $create{DomainName});
is($contacts->{Domain}, $create{DomainName});
is($contacts->{domainnameid}, $result->{DomainID});

my $tests = 9;

foreach my $key (keys %{$create{Registrant}}) {
    is($contacts->{Registrant}->{$key}, $create{Registrant}->{$key});
    is($contacts->{Tech}->{$key}, $create{Registrant}->{$key});
    is($contacts->{Admin}->{$key}, $create{Registrant}->{$key});
    is($contacts->{AuxBilling}->{$key}, $create{Registrant}->{$key});
    $tests += 4;
}

#use Data::Dumper();
#print STDERR Data::Dumper::Dumper \$contacts;

done_testing($tests);
