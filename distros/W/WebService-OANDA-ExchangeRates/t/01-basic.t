#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use Test::More;
use Module::Spy;

use WebService::OANDA::ExchangeRates;

my $api = WebService::OANDA::ExchangeRates->new( api_key => 'AN_API_KEY' );
isa_ok( $api, 'WebService::OANDA::ExchangeRates' );

my $raw_data = '{"success": "1"}';
my $spy
    = spy_on( $api->user_agent, 'get' )
    ->and_returns(
    HTTP::Response->new( 200, 'Ok', undef, $raw_data ) );

# validate headers
like(
    $api->user_agent->default_headers->header('user-agent'),
    qr{^WebService::OANDA::ExchangeRates/\d+(?:\.\d+)*},
    'user-agent header properly set'
);
is(
    $api->user_agent->default_headers->header('authorization'),
    'Bearer AN_API_KEY',
    'authorization header properly set'
);

my $base_url = 'https://www.oanda.com/rates/api/v1/';
is($api->base_url->as_string, $base_url, 'base_url is correct');

my @TESTS = (
    {   method       => 'get_currencies',
        args         => [],
        expected_url => $base_url . 'currencies.json'
    },
    {   method => 'get_remaining_quotes',
        args   => [],
        expected_url =>
            $base_url . 'remaining_quotes.json'
    },
    {   method       => 'get_rates',
        args         => [ base_currency => 'USD' ],
        expected_url => $base_url . 'rates/USD.json'
    },
);

foreach my $test_data (@TESTS) {
    my $method = $test_data->{method};

    my $response = $api->$method( @{ $test_data->{args} } );
    isa_ok( $response, "WebService::OANDA::ExchangeRates::Response" );
    is( $spy->calls_most_recent->[1],
        $test_data->{expected_url},
        "$method called the right url"
    );
    ok( $response->is_success,         "$method request is a success" );
    ok( !$response->is_error,          "$method is not an error" );
    ok( ref $response->data eq 'HASH', "$method response is deserialized" );
    is_deeply( $response->data, { success => 1 }, "$method data is correct" );
    is($response->raw_data, $raw_data, "$method raw data matches");
}

my $proxy = 'http://a.proxy.com:9000';
my $proxy_api = WebService::OANDA::ExchangeRates->new(
    api_key => 'AN_API_KEY',
    proxy   => $proxy,
);

is(
    $proxy_api->user_agent->proxy($proxy_api->base_url->scheme)->as_string,
    $proxy,
    'proxy is properly set'
);


done_testing();
