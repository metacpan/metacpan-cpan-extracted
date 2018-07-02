# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::PaymentMethodNonce;
use WebService::Braintree::TestHelper qw(sandbox);

subtest "creates a payment method nonce from a vaulted credit card" => sub {
    my $customer = WebService::Braintree::Customer->create->customer;
    isnt($customer->id, undef, '.. customer->id is defined');
    my $test_cc_number = cc_number();

    my $nonce = WebService::Braintree::TestHelper::nonce_for_new_credit_card({
        number => $test_cc_number,
        expirationMonth => "12",
        expirationYear => "2020",
        options => {
            validate => "false",
        },
    });

    isnt($nonce, undef, '.. nonce is defined');

    my $result = WebService::Braintree::PaymentMethod->create({
        payment_method_nonce => $nonce,
        customer_id => $customer->id,
        billing_address => {
            street_address => "123 Abc Way",
        },
    });
    validate_result($result) or return;

    isnt($result->payment_method, undef, '.. we have a payment method');
    my $token = $result->payment_method->token;

    my $found_credit_card = WebService::Braintree::CreditCard->find($token);
    isnt($found_credit_card, undef, '.. we can find the credit card from the token');

    {
        my $create_result = WebService::Braintree::PaymentMethodNonce->create($found_credit_card->token);
        validate_result($create_result) or return;

        ok($create_result->payment_method_nonce->nonce, '.. we get a nonce object');
        ok($create_result->payment_method_nonce->details, '.. we have details');
        is($create_result->payment_method_nonce->details->last_two, substr($test_cc_number, -2), '.. details match the credit card');
    }
};

subtest "thrown serror with invalid tokens" => sub {
    should_throw('NotFoundError', sub {
        my $create_result = WebService::Braintree::PaymentMethodNonce->create('not_a_token');
    }, '.. correctly raises an exception for a non existent token');
};

subtest "finds (fake) valid nonce, returns it" => sub {
    my $token = 'fake-valid-nonce';

    my $result = WebService::Braintree::PaymentMethodNonce->find($token);
    validate_result($result) or return;

    my $nonce = $result->payment_method_nonce;

    is($nonce->nonce, $token, '.. returns the correct nonce');
    is($nonce->type, 'CreditCard', '.. returns the correct type');
    is($nonce->details->last_two, '81', '.. details->last_two set correctly');
    is($nonce->details->card_type, 'Visa', '.. details->card_type set correctly');
};

subtest "returns null 3ds_info if there isn't any" => sub {
    my $nonce = WebService::Braintree::TestHelper::nonce_for_new_credit_card({
        number => cc_number(),
        expirationMonth => "11",
        expirationYear => "2099",
    });

    my $result = WebService::Braintree::PaymentMethodNonce->find($nonce);
    validate_result($result) or return;

    $nonce = $result->payment_method_nonce;
    is($nonce->three_d_secure_info, undef, '.. three_d_secure_info is null');
};

subtest "correctly raises and exception for a non existent token" => sub {
    should_throw('NotFoundError', sub {
        my $create_result = WebService::Braintree::PaymentMethodNonce->create('not_a_nonce');
    }, '.. correctly raises an exception for a non existent nonce');
};

done_testing();
