#!/usr/bin/perl

use Test::More;

BEGIN {
    use_ok( 'WebService::OANDA::ExchangeRates' );
    use_ok( 'WebService::OANDA::ExchangeRates::Response' );
}

done_testing();
