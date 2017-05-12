#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use Test::More;
use Module::Spy;

use WebService::OANDA::ExchangeRates;

my $api = WebService::OANDA::ExchangeRates->new(api_key => 'AN_API_KEY');
my $raw_data = '{"currencies":[{"code":"USD","description":"US Dollar"},{"code":"EUR","description":"Euro"}]}';

# mock response
my $spy = spy_on( $api->user_agent, 'get' )->and_returns(
    HTTP::Response->new( 200, 'Ok', undef, $raw_data )
);

is_deeply(
    $api->get_currencies->data,
    { USD => 'US Dollar', EUR => 'Euro' },
    "currencies list transforms properly"
);

done_testing();
