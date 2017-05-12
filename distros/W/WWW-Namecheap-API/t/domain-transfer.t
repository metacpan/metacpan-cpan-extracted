#!perl -T

use Test::More;
use WWW::Namecheap::API;

plan skip_all => "No API credentials defined" unless $ENV{TEST_APIUSER};

plan tests => 7;

my $api = WWW::Namecheap::API->new(
    System => 'test',
    ApiUser => $ENV{TEST_APIUSER},
    ApiKey => $ENV{TEST_APIKEY},
    DefaultIp => $ENV{TEST_APIIP} || '127.0.0.1',
);

isa_ok($api, 'WWW::Namecheap::API');

my $transfername = "wwwncapitransfer$$.com";
my $transfer = $api->domain->transfer(
    DomainName => $transfername,
    Years => 1,
    EPPCode => 'thisismyEPP',
);

is($transfer->{Transfer}, 'true');
like($transfer->{TransferID}, qr/^\d+$/);

my $status = $api->domain->transferstatus(TransferID => $transfer->{TransferID});
is($status->{TransferID}, $transfer->{TransferID});
like($status->{StatusID}, qr/^-?\d+$/);

my $transferlist = $api->domain->transferlist;

ok(grep { $_ eq $transfer->{TransferID} } map { $_->{ID} } @$transferlist);
ok(grep { $_ eq $transfername } map { $_->{DomainName} } @$transferlist);
