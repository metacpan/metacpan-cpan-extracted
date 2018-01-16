# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use DateTime;
use JSON;
use String::CamelCase qw(decamelize);
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
    my $cc_number = cc_number();
    my $credit_card_params = credit_card({
        number => $cc_number,
        customer_id => $customer_create->customer->id,
    });

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($result) or return;

    is $result->credit_card->last_4, cc_last4($cc_number), "sets credit card number";
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
    validate_result($result) or return;

    is($result->credit_card->last_4, "1111");
};

subtest "Create with security params" => sub {
    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        device_session_id => "abc123",
        fraud_merchant_id => "456"
    });

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($result) or return;
};

subtest "Failure Cases" => sub {
    my $result = WebService::Braintree::CreditCard->create(credit_card({
        customer_id => "dne",
    }));
    invalidate_result($result) or return;

    is $result->message, "Customer ID is invalid.", "Customer not found";
};

subtest "Create with Fail on Duplicate Payment Method" => sub {
    my $customer_id = $customer_create->customer->id;

    my $credit_card_params = credit_card({
        customer_id => $customer_id,
        options => {
            fail_on_duplicate_payment_method => 1,
        },
    });

    WebService::Braintree::CreditCard->create($credit_card_params);
    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    invalidate_result($result) or return;

    is $result->message, "Duplicate card exists in the vault.";
};

subtest "Create with Billing Address" => sub {
    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        billing_address => {
            first_name => "Barry",
            last_name => "Zuckercorn",
            street_address => "123 Fake St",
            locality => "Chicago",
            region => "Illinois",
            postal_code => "60647",
            country_code_alpha2 => "US",
        },
    });

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($result) or return;

    is $result->credit_card->billing_address->first_name, "Barry", "sets address attributes";
    is $result->credit_card->billing_address->last_name, "Zuckercorn";
    is $result->credit_card->billing_address->street_address, "123 Fake St";
};

subtest "delete" => sub {
    subtest "existing card" => sub {
        my $card = WebService::Braintree::CreditCard->create(credit_card({
            customer_id => $customer_create->customer->id,
        }));
        my $result = WebService::Braintree::CreditCard->delete($card->credit_card->token);
        validate_result($result) or return;
    };

    subtest "not found" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::CreditCard->delete("notAToken");
        });
    };
};

subtest "find" => sub {
    subtest "card exists" => sub {
        my $cc_number = cc_number();
        my $card = WebService::Braintree::CreditCard->create(credit_card({
            number => $cc_number,
            expiration_date => "12/15",
            customer_id => $customer_create->customer->id,
        }));
        my $result = WebService::Braintree::CreditCard->find($card->credit_card->token);
        is $result->last_4, cc_last4($cc_number);
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
        validate_result($response) or return;

        $response = $http->get_cards();
        validate_result($response) or return;

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
        my $card = WebService::Braintree::CreditCard->create(credit_card({
            customer_id => $customer_create->customer->id,
        }));

        my $result = WebService::Braintree::CreditCard->update(
            $card->credit_card->token, credit_card({
                number => "4009348888881881",
            }),
        );
        validate_result($result) or return;

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

subtest 'Card Types' => sub {
    foreach my $test (
        [ 'Debit', debit => 'Debit' => 'Yes' ],
        [ 'Payroll', payroll => 'Payroll' => 'Yes' ],
        [ 'Healthcare', healthcare => 'Healthcare' => 'Yes' ],
        [ 'Commercial', commercial => 'Commercial' => 'Yes' ],
        [ 'DurbinRegulated', durbin_regulated => 'DurbinRegulated' => 'Yes' ],
        [ 'Prepaid', prepaid => 'Prepaid' => 'Yes' ],
    ) {
        my ($type, $method, $class, $const) = @$test;
        subtest $type => sub {
            my $credit_card_params = credit_card({
                customer_id => $customer_create->customer->id,
                number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators->$type,
                options => {
                    verify_card => 1,
                },
            });

            my $result = WebService::Braintree::CreditCard->create($credit_card_params);
            validate_result($result) or return;

            is $result->credit_card->$method, "WebService::Braintree::CreditCard::$class"->$const, "credit_card->$method returns ${class}->${const}";
        };
    }

    foreach my $test (
        [ 'IssuingBank', issuing_bank => 'IssuingBank' ],
        [ 'CountryOfIssuance', country_of_issuance => 'CountryOfIssuance' ],
    ) { 
        my ($type, $method, $const) = @$test;
        subtest $type => sub {
            my $credit_card_params = credit_card({
                customer_id => $customer_create->customer->id,
                number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators->$type,
                options => {
                    verify_card => 1,
                },
            });

            my $result = WebService::Braintree::CreditCard->create($credit_card_params);
            validate_result($result) or return;

            is $result->credit_card->$method, WebService::Braintree::CreditCardDefaults->$const, "credit_card->$method returns CreditCardDefaults->$const";
        };

    }
};

subtest "card with negative card type identifiers" => sub {
    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::No,
        options => {
            verify_card => 1,
        },
    });

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($result) or return;

    foreach my $type (qw(
        Prepaid Debit Payroll Healthcare
        Commercial DurbinRegulated
    )) {
        my $method = decamelize($type);
        is $result->credit_card->$method, "WebService::Braintree::CreditCard::$type"->No, "credit_card->$method is $type->No";
    }
};

subtest "card without card type identifiers" => sub {
    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Unknown,
        options => {
            verify_card => 1,
        },
    });

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($result) or return;

    foreach my $type (qw(
        Prepaid Debit Payroll Healthcare
        Commercial DurbinRegulated
        IssuingBank CountryOfIssuance
    )) {
        my $method = decamelize($type);
        is $result->credit_card->$method, "WebService::Braintree::CreditCard::$type"->Unknown, "credit_card->$method is $type->Unknown";
    }
};

subtest "Venmo Sdk Payment Method Code" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk::generate_test_payment_method_code("4111111111111111"),
    });
    validate_result($result) or return;

    is($result->credit_card->bin, "411111");
    is($result->credit_card->last_4, "1111");
    ok $result->credit_card->is_venmo_sdk;
};

subtest "Invalid Venmo Sdk Payment Method Code" => sub {
    my $result = WebService::Braintree::CreditCard->create({
        customer_id => $customer_create->customer->id,
        venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk::InvalidPaymentMethodCode,
    });
    invalidate_result($result) or return;

    is($result->message, "Invalid VenmoSDK payment method code");
    is($result->errors->for('credit_card')->on('venmo_sdk_payment_method_code')->[0]->code, WebService::Braintree::ErrorCodes::CreditCard::InvalidVenmoSDKPaymentMethodCode);
};

subtest "Valid Venmo Sdk Session" => sub {
    my $result = WebService::Braintree::CreditCard->create(credit_card({
        customer_id => $customer_create->customer->id,
        options =>  {
            venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::Session,
        },
    }));
    validate_result($result) or return;

    ok $result->credit_card->is_venmo_sdk;
};

subtest "Invalid Venmo Sdk Session" => sub {
    my $result = WebService::Braintree::CreditCard->create(credit_card({
        customer_id => $customer_create->customer->id,
        options =>  {
            venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::InvalidSession,
        },
    }));
    validate_result($result) or return;

    not_ok $result->credit_card->is_venmo_sdk;
};

subtest credit => sub {
    plan skip_all => 'This returns unauthorized';
    my $cust_res = WebService::Braintree::Customer->create({
        credit_card => credit_card(),
    });
    validate_result($cust_res) or return;
    my $customer = $cust_res->customer;

    my $amount = amount(80,120);
    my $cred_res = WebService::Braintree::CreditCard->credit(
        $customer->credit_cards->[0]->token, {
            amount => $amount,
        },
    );
    validate_result($cred_res) or return;
    my $txn = $cred_res->transaction;

    cmp_ok($txn->amount, '==', $amount);
    is($txn->type, 'credit');
    is($txn->customer_details->id, $customer->id);
    is($txn->credit_card_details->token, $customer->credit_cards->[0]->token);
};

subtest sale => sub {
    my $cust_res = WebService::Braintree::Customer->create({
        credit_card => credit_card(),
    });
    validate_result($cust_res) or return;
    my $customer = $cust_res->customer;

    my $amount = amount(80,120);
    my $cred_res = WebService::Braintree::CreditCard->sale(
        $customer->credit_cards->[0]->token, {
            amount => $amount,
        },
    );
    validate_result($cred_res) or return;
    my $txn = $cred_res->transaction;

    cmp_ok($txn->amount, '==', $amount);
    is($txn->type, 'sale');
    is($txn->customer_details->id, $customer->id);
    is($txn->credit_card_details->token, $customer->credit_cards->[0]->token);
};

subtest expired_cards => sub {
    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        expiration_date => '01/2015',
    });

    my $card_result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($card_result) or return;
    my $credit_card = $card_result->credit_card;

    my $expired = WebService::Braintree::CreditCard->expired_cards();
    ok(!$expired->is_empty);
    my $have_card = 0;
    $expired->each(sub {
        my $card = shift;
        $have_card = 1 if $card->token eq $credit_card->token;
    });
    ok($have_card);
};

subtest expiring_between => sub {
    my $next_year = DateTime->now->year + 1;

    my $credit_card_params = credit_card({
        customer_id => $customer_create->customer->id,
        expiration_date => "06/${next_year}",
    });

    my $card_result = WebService::Braintree::CreditCard->create($credit_card_params);
    validate_result($card_result) or return;
    my $credit_card = $card_result->credit_card;

    my $values = WebService::Braintree::CreditCard->expiring_between(
        DateTime->new( month => 1, year => $next_year ),
        DateTime->new( month => 12, year => $next_year ),
    );
    ok(!$values->is_empty, 'Have at least 1 card expiring next year');

    my $have_card = 0;
    my $have_expired = 0;
    my $have_bad_year = 0;
    $values->each(sub {
        my $card = shift;
        $have_card = 1 if $card->token eq $credit_card->token;
        $have_expired = 1 if $card->expired;
        $have_bad_year = 1 if $card->expiration_year ne $next_year;
    });
    ok($have_card);
    ok(!$have_expired);
    ok(!$have_bad_year);
};

done_testing();
