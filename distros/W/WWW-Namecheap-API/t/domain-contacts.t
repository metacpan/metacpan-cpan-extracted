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

my %expected = (
    OrganizationName => 'WWW-Namecheap-API',
    FirstName => 'Create',
    LastName => 'Test',
    Address1 => '123 Fake Street',
    City => 'Univille',
    StateProvince => 'SD',
    PostalCode => '12345',
    Country => 'US',
    Phone => '+1.2125551212',
    Fax => '+1.5555555555',
    EmailAddress => 'twilde@cpan.org',
);

my %modified = (
    OrganizationName => 'WWW-Namecheap-API-Rocks',
    FirstName => 'Modify',
    LastName => 'Tester',
    Address1 => '12345 Fake Street',
    Address2 => 'Apt 1492',
    City => 'Univille',
    StateProvince => 'HI',
    PostalCode => '12346',
    Country => 'US',
    Phone => '+1.2125551212',
    EmailAddress => 'twilde@cpan.org',
);

my $testdomain = 'wwwnamecheapapi38449.com';
my $set1 = $api->domain->setcontacts(
    DomainName => $testdomain,
    Registrant => \%expected,
);
is($set1->{Domain}, $testdomain);
is($set1->{IsSuccess}, 'true');

my $contacts = $api->domain->getcontacts(DomainName => $testdomain);
is($contacts->{Domain}, $testdomain);

my $tests = 4;

foreach my $contact (qw(Registrant Tech Admin AuxBilling)) {
    foreach my $key (keys %{$contacts->{$contact}}) {
        if ($key eq 'StateProvince') {
            is($contacts->{$contact}->{$key}, $expected{StateProvince});
        } elsif ($key eq 'StateProvinceChoice') {
            next; # unable to test unknown API behavior
        } elsif ($expected{$key}) {
            is($contacts->{$contact}->{$key}, $expected{$key});
        } elsif ($key eq 'ReadOnly') {
            is($contacts->{$contact}->{$key}, 'false');
        } else  {
            ok(ref($contacts->{$contact}->{$key}) eq 'HASH'
               && keys(%{$contacts->{$contact}->{$key}}) == 0,
               'Blank expected == empty hash')
        }
        $tests++;
    }
}

my $set2 = $api->domain->setcontacts(
    DomainName => $testdomain,
    Registrant => \%modified,
    Tech => \%modified,
);
is($set2->{Domain}, $testdomain);
is($set2->{IsSuccess}, 'true');

my $contacts2 = $api->domain->getcontacts(DomainName => $testdomain);
is($contacts2->{Domain}, $testdomain);

$tests += 3;

foreach my $contact (qw(Registrant Tech Admin AuxBilling)) {
    foreach my $key (keys %{$contacts2->{$contact}}) {
        if ($key eq 'StateProvince') {
            is($contacts2->{$contact}->{$key}, $modified{StateProvince});
        } elsif ($key eq 'StateProvinceChoice') {
            next; # unable to test unknown API behavior
        } elsif ($modified{$key}) {
            is($contacts2->{$contact}->{$key}, $modified{$key});
        } elsif ($key eq 'ReadOnly') {
            is($contacts2->{$contact}->{$key}, 'false');
        } else  {
            ok(ref($contacts2->{$contact}->{$key}) eq 'HASH'
               && keys(%{$contacts2->{$contact}->{$key}}) == 0,
               'Blank modified == empty hash')
        }
        $tests++;
    }
}

done_testing($tests);
