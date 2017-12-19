use strict;
use warnings;

use Test::More;

use Scalar::Util qw( blessed );
use Test::Fatal qw( exception );
use WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST;

use lib 't/lib';
use Util;

## no critic (ProhibitCallsToUnexportedSubs)
## no critic (RequireExplicitInclusion)
{
    my $ppa = Util::mocked_ppa;
    my $mocker
        = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
        secure_token_id => 'NOPPREF' );

    my $response = Util::mocked_ppa->get_response_from_silent_post(
        { params => $mocker->credit_card_success } );

    is(
        blessed $response,
        'WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::CreditCard',
        'CreditCard class'
    );
    ok( $response->transaction_time,           'transaction_time' );
    ok( $response->pnref,                      'pnref' );
    ok( !$response->ppref,                     'ppref missing' );
    ok( !$response->is_paypal_transaction,     'not paypal transaction' );
    ok( $response->is_credit_card_transaction, 'is_credit_card_transaction' );
}

{
    my @valids = (
        '0123',
        '1234',
        '0000',
        1234,
        2340,
    );

    my @invalids = (
        0,
        'no',
        'test',
        1,
        12,
        123,
    );

    for my $input (@valids) {
        my $mocker
            = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
            secure_token_id => 'NOPPREF' );

        my $response = Util::mocked_ppa->get_response_from_silent_post(
            {
                params => {
                    %{ $mocker->credit_card_success },
                    ACCT => $input,
                },
            },
        );

        is(
            blessed $response,
            'WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::CreditCard',
            'CreditCard class'
        );
        ok( $response->transaction_time,       'transaction_time' );
        ok( $response->pnref,                  'pnref' );
        ok( !$response->ppref,                 'ppref missing' );
        ok( !$response->is_paypal_transaction, 'not paypal transaction' );
        ok(
            $response->is_credit_card_transaction,
            'is_credit_card_transaction'
        );
        is(
            $response->card_last_four_digits,
            $input,
            'expected card last four digits',
        );
    }

    for my $input (@invalids) {
        my $mocker
            = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
            secure_token_id => 'NOPPREF' );

        my $response = Util::mocked_ppa->get_response_from_silent_post(
            {
                params => {
                    %{ $mocker->credit_card_success },
                    ACCT => $input,
                },
            },
        );

        my $ex = exception { $response->card_last_four_digits };

        like(
            $ex,
            qr/must be 4 digits/,
            $input
                . ' is not a valid example the last 4 digits of a credit card',
        );
    }
}

# Ensure PPREF is now present in response
{
    my $ppa = Util::mocked_ppa;
    my $mocker
        = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
        secure_token_id => 'FOOBAR' );

    my $response = Util::mocked_ppa->get_response_from_silent_post(
        { params => $mocker->credit_card_success } );

    ok( $response->ppref, 'ppref present' );
}

done_testing();
