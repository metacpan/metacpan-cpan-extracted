# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use JSON;
use WebService::Braintree;
use WebService::Braintree::CreditCardNumbers::CardTypeIndicators;
use WebService::Braintree::CreditCardDefaults;
use WebService::Braintree::ErrorCodes::CreditCard;
use WebService::Braintree::Test;
use WebService::Braintree::TestHelper qw(sandbox);

my $customer_create = WebService::Braintree::Customer->create({
    first_name => "Walter",
    last_name => "Weatherman",
});

subtest "Create with S2S" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "5431111111111111",
        expiration_date => "12/15"
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    ok $result->is_success, "result returns no errors";
    is $result->credit_card->last_4, "1111", "sets credit card number";
    ok $result->credit_card->unique_number_identifier =~ /\A\w{32}\z/;
    not_ok $result->credit_card->is_venmo_sdk;
    ok $result->credit_card->image_url
};

subtest "create with credit card nonce" => sub {
    my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card("4111111111111111", "");

    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        payment_method_nonce => $nonce
    });

    ok $result->is_success;
    is($result->credit_card->last_4, "1111");
};

subtest "Create with security params" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "5431111111111111",
        expiration_date => "12/15",
        device_session_id => "abc123",
        fraud_merchant_id => "456"
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    ok $result->is_success, "result returns no errors";
};

subtest "Failure Cases" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => "dne",
        number => '5431111111111111',
        expiration_date => "12/15",
    });

    not_ok $result->is_success;
    is $result->message, "Customer ID is invalid.", "Customer not found";
};

subtest "Create with Fail on Duplicate Payment Method" => sub {
    my $customer_id = $customer_create->customer->id;

    my $credit_card_params = {
        customer_id => $customer_id,
        number => "5431111111111111",
        expiration_date => "12/15",
        options => {
            fail_on_duplicate_payment_method => 1,
        },
    };

    WebService::Braintree::CreditCard->create($credit_card_params);
    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    not_ok $result->is_success;
    is $result->message, "Duplicate card exists in the vault.";
};

subtest "Create with Billing Address" => sub {
    my $credit_card_params =  {
        customer_id => $customer_create->customer->id,
        number => "5431111111111111",
        expiration_date => "12/15",
        billing_address => {
            first_name => "Barry",
            last_name => "Zuckercorn",
            street_address => "123 Fake St",
            locality => "Chicago",
            region => "Illinois",
            postal_code => "60647",
            country_code_alpha2 => "US",
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    ok $result->is_success, "result returns no errors";
    is $result->credit_card->billing_address->first_name, "Barry", "sets address attributes";
    is $result->credit_card->billing_address->last_name, "Zuckercorn";
    is $result->credit_card->billing_address->street_address, "123 Fake St";
};

subtest "delete" => sub {
    subtest "existing card" => sub {
        my $card = WebService::Braintree::CreditCard->create({
            number => "5431111111111111",
            expiration_date => "12/15",
            customer_id => $customer_create->customer->id,
        });
        my $result = WebService::Braintree::CreditCard->delete($card->credit_card->token);
        ok $result->is_success;
    };

    subtest "not found" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::CreditCard->delete("notAToken");
        });
    };
};

subtest "find" => sub {
    subtest "card exists" => sub {
        my $card = WebService::Braintree::CreditCard->create({
            number => "5431111111111111",
            expiration_date => "12/15",
            customer_id => $customer_create->customer->id,
        });
        my $result = WebService::Braintree::CreditCard->find($card->credit_card->token);
        is $result->last_4, "1111";
        is $result->expiration_month, "12";
    };

    subtest "card does not exist" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::CreditCard->find("notAToken");
        });
    };
};

subtest "from_nonce" => sub {
    subtest "returns the payment method for the provided nonce" => sub {
        my $customer = $customer_create->customer;
        my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card("4111111111111111", $customer->id);
        my $credit_card = WebService::Braintree::CreditCard->from_nonce($nonce);

        is($credit_card->last_4, "1111");
    };

    subtest "fails if nonce is empty" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::CreditCard->from_nonce("");
        });
    };

    subtest "fails if nonce points to a shared card" => sub {
        my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card("4111111111111111", "");

        should_throw_containing("not found", sub {
            WebService::Braintree::CreditCard->from_nonce($nonce);
        });
    };

    subtest "fails if nonce is locked" => sub {
        my $config = WebService::Braintree::TestHelper->config;
        my $raw_client_token = WebService::Braintree::TestHelper::generate_decoded_client_token();
        my $client_token = decode_json($raw_client_token);
        my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};

        my $http = WebService::Braintree::ClientApiHTTP->new(
            config => $config,
            fingerprint => $authorization_fingerprint,
            shared_customer_identifier => "fake_identifier",
            shared_customer_identifier_type => "testing"
        );

        my $response = $http->add_card({
            share => "true",
            credit_card => {
                number => "4111111111111111",
                expiration_date => "11/2099"
            }
        });
        ok $response->is_success;

        $response = $http->get_cards();
        ok $response->is_success;
        my $nonce = decode_json($response->content)->{"paymentMethods"}[0]{"nonce"};

        should_throw_containing("locked", sub {
            WebService::Braintree::CreditCard->from_nonce($nonce);
        });
    };

    subtest "fails if nonce is already consumed" => sub {
        my $customer = $customer_create->customer;
        my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card("4111111111111111", $customer->id);

        WebService::Braintree::CreditCard->from_nonce($nonce);
        should_throw_containing("consumed", sub {
            WebService::Braintree::CreditCard->from_nonce($nonce);
        });
    };
};

subtest "update" => sub {

    subtest "existing card" => sub {
        my $card = WebService::Braintree::CreditCard->create({number => "5431111111111111", expiration_date => "12/15", customer_id => $customer_create->customer->id});
        my $result = WebService::Braintree::CreditCard->update($card->credit_card->token, {
            number => "4009348888881881",
            expiration_date => "03/15"
        });

        ok $result->is_success, "returns no errors";
        is $result->credit_card->last_4, "1881", "sets new credit card number";
    };

    subtest "not found" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::CreditCard->update("notAToken", {
                number => "1234567890123456",
            });
        });
    };

};

# Consider merging the following subtests in a loop
subtest "debit" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Debit,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->debit, WebService::Braintree::CreditCard::Debit::Yes;
};

subtest "payroll" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Payroll,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->payroll, WebService::Braintree::CreditCard::Payroll::Yes;
};

subtest "healthcare" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Healthcare,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->healthcare, WebService::Braintree::CreditCard::Healthcare::Yes;
};

subtest "commercial" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Commercial,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->commercial, WebService::Braintree::CreditCard::Commercial::Yes;
};

subtest "durbin_regulated" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::DurbinRegulated,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->durbin_regulated, WebService::Braintree::CreditCard::DurbinRegulated::Yes;
};

subtest "prepaid" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Prepaid,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->prepaid, WebService::Braintree::CreditCard::Prepaid::Yes;
};

subtest "issuing_bank" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::IssuingBank,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->issuing_bank, WebService::Braintree::CreditCardDefaults::IssuingBank;
};

subtest "country_of_issuance" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::CountryOfIssuance,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->country_of_issuance, WebService::Braintree::CreditCardDefaults::CountryOfIssuance;
};
### TO HERE

subtest "card with negative card type indentifiers" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::No,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->prepaid, WebService::Braintree::CreditCard::Prepaid::No;
    is $result->credit_card->debit, WebService::Braintree::CreditCard::Debit::No;
    is $result->credit_card->payroll, WebService::Braintree::CreditCard::Payroll::No;
    is $result->credit_card->healthcare, WebService::Braintree::CreditCard::Healthcare::No;
    is $result->credit_card->commercial, WebService::Braintree::CreditCard::Commercial::No;
    is $result->credit_card->durbin_regulated, WebService::Braintree::CreditCard::DurbinRegulated::No;
};

subtest "card without card type identifiers" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Unknown,
        expiration_date => "12/15",
        options => {
            verify_card => 1,
        },
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    is $result->credit_card->prepaid, WebService::Braintree::CreditCard::Prepaid::Unknown;
    is $result->credit_card->debit, WebService::Braintree::CreditCard::Debit::Unknown;
    is $result->credit_card->payroll, WebService::Braintree::CreditCard::Payroll::Unknown;
    is $result->credit_card->healthcare, WebService::Braintree::CreditCard::Healthcare::Unknown;
    is $result->credit_card->commercial, WebService::Braintree::CreditCard::Commercial::Unknown;
    is $result->credit_card->durbin_regulated, WebService::Braintree::CreditCard::DurbinRegulated::Unknown;
    is $result->credit_card->issuing_bank, WebService::Braintree::CreditCard::IssuingBank::Unknown;
    is $result->credit_card->country_of_issuance, WebService::Braintree::CreditCard::CountryOfIssuance::Unknown;
};

subtest "Venmo Sdk Payment Method Code" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk::generate_test_payment_method_code("4111111111111111"),
    });

    ok $result->is_success;
    is($result->credit_card->bin, "411111");
    is($result->credit_card->last_4, "1111");
    ok $result->credit_card->is_venmo_sdk;
};

subtest "Invalid Venmo Sdk Payment Method Code" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk::InvalidPaymentMethodCode,
    });

    not_ok $result->is_success;
    is($result->message, "Invalid VenmoSDK payment method code");
    is($result->errors->for('credit_card')->on('venmo_sdk_payment_method_code')->[0]->code, WebService::Braintree::ErrorCodes::CreditCard::InvalidVenmoSDKPaymentMethodCode);
};

subtest "Valid Venmo Sdk Session" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        number => "5431111111111111",
        expiration_date => "12/15",
        options =>  {
            venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::Session,
        },
    });

    ok $result->is_success;
    ok $result->credit_card->is_venmo_sdk;
};

subtest "Invalid Venmo Sdk Session" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        number => "5431111111111111",
        expiration_date => "12/15",
        options =>  {
            venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::InvalidSession,
        },
    });

    ok $result->is_success;
    not_ok $result->credit_card->is_venmo_sdk;
};

done_testing();
