use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Web::MarketReceipt
    Web::MarketReceipt::Order
    Web::MarketReceipt::Verifier
    Web::MarketReceipt::Verifier::AppStore
    Web::MarketReceipt::Verifier::GooglePlay
);

done_testing;
