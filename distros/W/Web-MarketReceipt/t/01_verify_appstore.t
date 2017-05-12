use strict;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

use Web::MarketReceipt::Verifier::AppStore;

subtest 'verify before ios7 receipt type' => sub {
    my $mock = mock_guard('Web::MarketReceipt::Verifier::AppStore', {
        '_send_request' => sub {
            return {
                status  => 0,
                receipt => {
                    product_id                => '123456',
                    original_transaction_id   => 'abcdefg12345',
                    original_purchase_date_ms => 12345678,
                    quantity                  => 1,
                },
            }
        }
    });

    my $receipt = 'before ios7 receipt type';
    my $result = Web::MarketReceipt::Verifier::AppStore->verify(
        receipt => $receipt,
    );

    isa_ok $result, 'Web::MarketReceipt';
    ok $result->is_success;
    is scalar @{$result->orders}, 1;
    my $order = $result->orders->[0];
    is $order->product_identifier, 123456;
    is $order->unique_identifier, 'AppStore:' . 'abcdefg12345';
};

# refs: https://developer.apple.com/jp/documentation/ValidateAppStoreReceipt.pdf
subtest 'verify after ios7 receipt type' => sub {
    my $mock = mock_guard('Web::MarketReceipt::Verifier::AppStore', {
        '_send_request' => sub {
            return {
                status  => 0,
                receipt => {
                    bundle_id                    => '123456789',
                    application_version          => '1.2.3',
                    original_application_version => '1.0',
                    expiration_date              => 1234567,
                    in_app                       => [{
                        is_trial_period            => 'false',
                        purchase_date              => '2016-08-09 03:44:53 Etc/GMT',
                        purchase_date_pst          => '2016-08-08 20:44:53 America/Los_Angeles',
                        purchase_date_ms           => '1470714293000',
                        original_purchase_date     => '2016-08-09 03:44:53 Etc/GMT',
                        original_purchase_date_ms  => '1470714293000',
                        original_purchase_date_pst => '2016-08-08 20:44:53 America/Los_Angeles',
                        quantity                   => '1',
                        product_id                 => '123456',
                        transaction_id             => 'abcdefg12345',
                        original_transaction_id    => 'abcdefg12345',
                        purchase_date              => 1234567,
                        original_purchase_date     => 1234444,
                    }, {
                        is_trial_period            => 'false',
                        purchase_date              => '2016-08-09 03:44:53 Etc/GMT',
                        purchase_date_pst          => '2016-08-08 20:44:53 America/Los_Angeles',
                        purchase_date_ms           => '1470714293000',
                        original_purchase_date     => '2016-08-09 03:44:53 Etc/GMT',
                        original_purchase_date_ms  => '1470714293000',
                        original_purchase_date_pst => '2016-08-08 20:44:53 America/Los_Angeles',
                        quantity                   => '1',
                        product_id                 => '123456',
                        transaction_id             => '12345abcdefg',
                        original_transaction_id    => '12345abcdefg',
                        purchase_date              => 12345678,
                        original_purchase_date     => 12344445,
                    }],
                },
            }
        }
    });

    my $receipt = 'after ios7 receipt type';
    my $result = Web::MarketReceipt::Verifier::AppStore->verify(
        receipt => $receipt,
    );

    isa_ok $result, 'Web::MarketReceipt';
    ok $result->is_success;
    is scalar @{$result->orders}, 2;
    my $order = $result->orders->[0];
    is $order->product_identifier, 123456;
    is $order->unique_identifier, 'AppStore:' . 'abcdefg12345';
};

done_testing;
