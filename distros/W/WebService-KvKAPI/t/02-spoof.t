use strict;
use warnings;
use Test::More 0.96 tests => 11;
use Test::Exception;

use WebService::KvKAPI::Spoof;
use Sub::Override;
use Test::Mock::One;
use Test::Deep;

my $api = WebService::KvKAPI::Spoof->new(
    api_key => 'foobar',
);

my @methods = qw(
    search
    profile
    api_call
    _build_open_api_client
);

foreach (@methods) {
    can_ok($api, $_);
}

my $client = $api->client;
isa_ok($client, "OpenAPI::Client");

my @openapi_operations = qw(
    CompaniesTest_GetCompaniesBasicV2
    CompaniesTest_GetCompaniesExtendedV2
);

foreach (@openapi_operations) {
    can_ok($client, $_);
}

my $override = Sub::Override->new(
    'WebService::KvKAPI::api_call' => sub {
        my ($self, $op, $params) = @_;
        is($op, 'CompaniesTest_GetCompaniesBasicV2', 'Got the spoof call for _search');
        cmp_deeply($params, { foo => 'bar' }, "... with the correct parameters");
    }
);

$api->_search({ foo => 'bar'});

$override->replace(
    'WebService::KvKAPI::api_call' => sub {
        my ($self, $op, $params) = @_;
        is($op, 'CompaniesTest_GetCompaniesExtendedV2', 'Got the spoof call for profile');
        cmp_deeply($params, { foo => 'bar' }, "... with the correct parameters");
    }
);

$api->_profile({foo => 'bar'});
