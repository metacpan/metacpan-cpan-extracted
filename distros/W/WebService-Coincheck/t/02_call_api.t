use strict;
use warnings;
use Test::More;

use WebService::Coincheck;

unless ($ENV{TEST_WEBSERVICE_COINCHECK}) {
    plan( skip_all => "Please set \$ENV{TEST_WEBSERVICE_COINCHECK}, and run test $0" );
}

my $coincheck = WebService::Coincheck->new(
    access_key => 'YOUR_ACCESS_KEY',
    secret_key => 'YOUR_SECRET_KEY',
);

note $coincheck->order->opens;

note $coincheck->order->create({
    pair       => 'btc_jpy',
    order_type => 'buy',
    rate       => '100000',
    amount     => '0.001',
});

ok 1;

done_testing;
