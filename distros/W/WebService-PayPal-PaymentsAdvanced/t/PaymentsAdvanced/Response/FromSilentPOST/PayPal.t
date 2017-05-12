use strict;
use warnings;

use Test::More;

use Scalar::Util qw( blessed );
use WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST;

use lib 't/lib';
use Util;

my $ppa    = Util::mocked_ppa;
my $mocker = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
    secure_token_id => 'FOO' );

my $response = $ppa->get_response_from_silent_post(
    { params => $mocker->paypal_success } );

is(
    blessed $response,
    'WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::PayPal',
    'PayPal class'
);
ok( $response->transaction_time,            'transaction_time' );
ok( $response->ppref,                       'ppref' );
ok( $response->is_paypal_transaction,       'is_paypal_transaction' );
ok( !$response->is_credit_card_transaction, 'not credit card' );

done_testing();
