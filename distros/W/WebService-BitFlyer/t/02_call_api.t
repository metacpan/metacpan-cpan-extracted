use strict;
use warnings;
use Test::More;

use WebService::BitFlyer;

unless ($ENV{TEST_WEBSERVICE_BITFLYER}) {
    plan( skip_all => "Please set \$ENV{TEST_WEBSERVICE_BITFLYER}, and run test $0" );
}

my $bf = WebService::BitFlyer->new(
    access_key => 'ACCESS_KEY',
    secret_key => 'SECRET_KEY',
);

# public API
#note $bf->api->markets;
#note $bf->api->board;
#note $bf->api->ticker;
#note $bf->api->market_executions;
#note $bf->api->boardstate;
#note $bf->api->health;
#note $bf->api->chats;

# Private API
#note $bf->api->permissions;
#note $bf->api->balance;
#note $bf->api->collateral;
#note $bf->api->collateralaccounts;
#note $bf->api->addresses;
#note $bf->api->coinins;
#note $bf->api->coinouts;
#note $bf->api->bankaccounts;
#note $bf->api->deposits;
#note $bf->api->withdraw();
#note $bf->api->withdrawals;
#note $bf->api->order(
#  product_code     => 'BTC_JPY',
#  child_order_type => 'LIMIT',
#  side             => 'BUY',
#  price            => 1000000,
#  size             => 0.001,
#  minute_to_expire => 43200,
#);
#note $bf->api->cancel_order(
#  product_code => 'BTC_JPY',
#  child_order_acceptance_id => 'JRF*****',
#);
#note $bf->api->cancel_all;
#note $bf->api->orders;
#note $bf->api->executions;
#note $bf->api->trading_commission;

ok 1;

done_testing;
