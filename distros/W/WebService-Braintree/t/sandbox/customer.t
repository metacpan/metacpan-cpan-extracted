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
use WebService::Braintree::TestHelper qw(sandbox);
use WebService::Braintree::Test;
use WebService::Braintree::SandboxValues::Nonce;

my $customer_attributes = {
    first_name => "Johnny",
    last_name => "Doe",
    company => "Braintree",
    email => 'johnny@example.com',
    phone  => "312.555.0123",
    website => "www.example.com",
};

my $customer_with_cc_and_billing = {
    first_name => "Johnny",
    last_name => "Doe",
    company => "Braintree",
    credit_card => credit_card({
        billing_address => {
            street_address => "2 E Main St",
            extended_address => "Apt 4",
            locality => "Chicago",
            region => "Illinois",
            postal_code => "60647",
            country_code_alpha2 => "US",
        },
    }),
};

subtest "Create:S2S" => sub {
    subtest "simple" => sub {
        my $result = WebService::Braintree::Customer->create($customer_attributes);
        validate_result($result) or return;

        is($result->customer->first_name, "Johnny", "sets customer attributes (first name)");
        isnt($result->customer->id, undef, "customer id != blank");
    };

    subtest "with CC and billing address" => sub {
        my $result = WebService::Braintree::Customer->create($customer_with_cc_and_billing);
        validate_result($result) or return;

        is($result->customer->first_name, "Johnny", "sets customer attributes (first name)");
        is($result->customer->addresses->[0]->street_address, "2 E Main St", "sets deeply nested attributes");
        is($result->customer->credit_cards->[0]->last_4, cc_last4($customer_with_cc_and_billing->{credit_card}{number}));
        ok $result->customer->credit_cards->[0]->unique_number_identifier =~ /\A\w{32}\z/;
    };

    subtest "with venmo sdk payment method code" => sub {
        my $result = WebService::Braintree::Customer->create({
            first_name => "Johnny",
            last_name => "Doe",
            credit_card => {
                venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk::VisaPaymentMethodCode,
            },
        });
        validate_result($result) or return;

        is($result->customer->credit_cards->[0]->last_4, "1111");
    };

    subtest "with credit card nonce" => sub {
        my $cc_number = cc_number('visa');
        my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card($cc_number, "");

        my $result = WebService::Braintree::Customer->create({
            first_name => "Johnny",
            last_name => "Doe",
            credit_card => {
                payment_method_nonce => $nonce,
            },
        });
        validate_result($result) or return;

        is($result->customer->credit_cards->[0]->last_4, cc_last4($cc_number));
    };

    subtest "with paypal payment method nonce" => sub {
        plan skip_all => 'Error with paypal nonces';
        my $nonce = WebService::Braintree::TestHelper::generate_future_payment_paypal_nonce();
        my $customer_result = WebService::Braintree::Customer->create({
            payment_method_nonce => $nonce,
        });
        validate_result($customer_result) or return;

        my $customer = $customer_result->customer;
        isnt($customer->paypal_accounts, undef);
        is(scalar @{$customer->paypal_accounts}, 1);
    };

    subtest "with venmo sdk session" => sub {
        plan skip_all => 'This test no longer works, even though it used to.';
        my $result = WebService::Braintree::Customer->create({
            first_name => "Johnny",
            last_name => "Doe",
            credit_card => credit_card({
                options => {
                    venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::Session,
                },
            }),
        });
        validate_result($result) or return;

        ok $result->customer->credit_cards->[0]->venmo_sdk;
    };

    subtest "with security params" => sub {
        my $result = WebService::Braintree::Customer->create({
            first_name => "Johnny",
            last_name => "Doe",
            credit_card => credit_card({
                device_session_id => "abc123",
                fraud_merchant_id => "456",
                billing_address => {
                    street_address => "2 E Main St",
                    extended_address => "Apt 4",
                    locality => "Chicago",
                    region => "Illinois",
                    postal_code => "60647",
                    country_code_alpha2 => "US",
                },
            }),
        });
        validate_result($result) or return;
    };
};

subtest "delete" => sub {
    subtest "existing customer" => sub {
        my $create = WebService::Braintree::Customer->create($customer_attributes);
        validate_result($create) or return;

        my $delete = WebService::Braintree::Customer->delete($create->customer->id);
        validate_result($delete) or return;
    };

    subtest "customer doesn't exist" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::Customer->delete("foo");
        }, "throws NotFoundError if customer doesn't exist");
    };
};

subtest "find" => sub {
    subtest "existing customer" => sub {
        my $create = WebService::Braintree::Customer->create($customer_attributes);
        my $customer = WebService::Braintree::Customer->find($create->customer->id);
        is $customer->id, $create->customer->id, "finds the correct customer";
        is $customer->first_name, "Johnny", "gets customer details (First name)";
    };

    subtest "doesn't exist" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::Customer->find("foo");
        }, "throws NotFoundError if customer doesn't exist");
    };
};

subtest "update" => sub {
    subtest "existing simple customer" => sub {
        my $create = WebService::Braintree::Customer->create($customer_attributes);
        my $update = WebService::Braintree::Customer->update($create->customer->id, {first_name => "Timmy"});
        validate_result($update) or return;

        is $update->customer->first_name, "Timmy", "updates attribute correctly";
    };

    subtest "add CC/address details existing simple customer" => sub {
        my $create = WebService::Braintree::Customer->create($customer_attributes);
        my $update = WebService::Braintree::Customer->update($create->customer->id, $customer_with_cc_and_billing);
        validate_result($update) or return;

        is $update->customer->addresses->[0]->street_address, "2 E Main St", "sets deeply nested attributes";
    };

    subtest "update existing customer CC/Address details" => sub {
        my $create = WebService::Braintree::Customer->create($customer_with_cc_and_billing);

        my $update = WebService::Braintree::Customer->update($create->customer->id, {
            credit_card => {
                number => "4009348888881881",
                expiration_date => "09/2013",
                options => {
                    update_existing_token => $create->customer->credit_cards->[0]->token,
                },
            },
        });
        validate_result($update) or return;

        is $update->customer->credit_cards->[0]->last_4, "1881", "set credit card properly";
    };

    subtest "update existing customer billing address details" => sub {
        my $create = WebService::Braintree::Customer->create($customer_with_cc_and_billing);
        my $update = WebService::Braintree::Customer->update($create->customer->id, {
            credit_card => {
                number => "4009348888881881",
                options => {
                    update_existing_token => $create->customer->credit_cards->[0]->token,
                },
                billing_address => {
                    street_address => "4 E Main St",
                    options => {
                        update_existing => "true",
                    },
                },
            },
        });
        validate_result($update) or return;

        is $update->customer->addresses->[0]->street_address, "4 E Main St", "update billing street address";
    };

    subtest "doesn't exist" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::Customer->update("baz", {
                first_name => "Timmy",
            });
        }, "throws error if customer doesn't exist");
    };

    subtest "invalid params" => sub {
        should_throw("ArgumentError", sub {
            WebService::Braintree::Customer->update('foo', {
                "invalid_param" => "1",
            });
        }, "throws arg error");
    };

    subtest "update accepts payment method nonce" => sub {
        my $customer_result = WebService::Braintree::Customer->create({
            credit_card => credit_card(),
        });

        my $update_result = WebService::Braintree::Customer->update(
            $customer_result->customer->id,
            {
                payment_method_nonce => WebService::Braintree::SandboxValues::Nonce->PAYPAL_FUTURE_PAYMENT,
            });

        my $updated_customer = $update_result->customer;
        is(@{$updated_customer->paypal_accounts}, 1);
        is(@{$updated_customer->credit_cards}, 1);
        is(@{$updated_customer->payment_methods}, 2);
    };
};

subtest "Search" => sub {
    subtest "search on paypal account email" => sub {
        my $customer_result = WebService::Braintree::Customer->create({
            payment_method_nonce => WebService::Braintree::SandboxValues::Nonce->PAYPAL_FUTURE_PAYMENT,
        });

        my $customer = $customer_result->customer;
        my $search_result = WebService::Braintree::Customer->search(sub {
            my $search = shift;
            $search->id->is($customer->id);
            $search->paypal_account_email->is($customer->paypal_accounts->[0]->email);
        });

        is($search_result->maximum_size, 1);
    };
};

subtest 'credit' => sub {
    plan skip_all => 'Transaction->credit() returns unauthorized';

    my $cust_result = WebService::Braintree::Customer->create({
        credit_card => credit_card(),
    });
    validate_result($cust_result) or return;
    my $customer = $cust_result->customer;

    my $amount = amount(80, 120);
    my $cred_result = WebService::Braintree::Customer->credit(
        $customer->id, {
            amount => $amount,
        },
    );
    validate_result($cred_result) or return;
    my $txn = $cred_result->transaction;

    cmp_ok($txn->amount, '==', $amount);
    is($txn->type, 'credit');
    is($txn->customer_details->id, $customer->id);
    is($txn->credit_card_details->token, $customer->credit_cards->[0]->token);
};

subtest 'sale' => sub {
    my $cust_result = WebService::Braintree::Customer->create({
        credit_card => credit_card(),
    });
    validate_result($cust_result) or return;
    my $customer = $cust_result->customer;

    my $amount = amount(80, 120);
    my $sale_result = WebService::Braintree::Customer->sale(
        $customer->id, {
            amount => $amount,
        },
    );
    validate_result($sale_result) or return;
    my $txn = $sale_result->transaction;

    cmp_ok($txn->amount, '==', $amount);
    is($txn->type, 'sale');
    is($txn->customer_details->id, $customer->id);
    is($txn->credit_card_details->token, $customer->credit_cards->[0]->token);

    my $transactions = WebService::Braintree::Customer->transactions(
        $customer->id,
    );

    ok(!$transactions->is_empty);
    is($transactions->first->id, $txn->id);
};

done_testing();
