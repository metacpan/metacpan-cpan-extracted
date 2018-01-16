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
use WebService::Braintree::CreditCardNumbers::CardTypeIndicators;
use WebService::Braintree::ErrorCodes::Transaction;
use WebService::Braintree::ErrorCodes::Descriptor;
use WebService::Braintree::CreditCardDefaults;
use WebService::Braintree::Nonce;
use WebService::Braintree::SandboxValues::Nonce;
use WebService::Braintree::SandboxValues::TransactionAmount;
use WebService::Braintree::Test;
use WebService::Braintree::Transaction::Status;
use WebService::Braintree::Transaction::PaymentInstrumentType;

my $params = {
    amount => amount(40, 60),
    credit_card => credit_card(),
    descriptor => {
        name => "abc*def",
        phone => "1234567890",
        url => "ebay.com",
    },
};

my @examples = qw(credit sale);
foreach my $method (@examples) {
    subtest "Successful Transaction for $method" => sub {
        plan skip_all => 'These return unauthorized (unknown why)';

        my $result = WebService::Braintree::Transaction->$method($params);
        validate_result($result) or return;

        is($result->message, "", "$method result has no message");
        is($result->transaction->credit_card->last_4, cc_last4($params->{credit_card}{number}));
        is($result->transaction->voice_referral_number, undef);
        is($result->transaction->descriptor->name, "abc*def");
        is($result->transaction->descriptor->phone, "1234567890");
        is($result->transaction->descriptor->url, "ebay.com");
    };
}

subtest "descriptor validations" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(1, 10),
        credit_card => {
            number => cc_number('fraud'),
            expiration_date => "05/16",
        },
        descriptor => {
            name => "abcdef",
            phone => "12345678",
            url => "12345678901234",
        },
    });
    invalidate_result($result) or return;

    is($result->errors->for("transaction")->for("descriptor")->on("name")->[0]->code, WebService::Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid);
    is($result->errors->for("transaction")->for("descriptor")->on("phone")->[0]->code, WebService::Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid);
    is($result->errors->for("transaction")->for("descriptor")->on("url")->[0]->code, WebService::Braintree::ErrorCodes::Descriptor::UrlFormatIsInvalid);
};

subtest "Fraud rejections" => sub {
    plan skip_all => "This does not create a fraud";

    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(1, 10),
        credit_card => {
            number => cc_number('fraud'),
            expiration_date => "05/16",
        },
    });
    invalidate_result($result) or return;

    is($result->message, "Gateway Rejected: fraud");
    is($result->transaction->gateway_rejection_reason, "fraud");
};

subtest "Custom Fields" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => credit_card(),
        custom_fields => {
            store_me => "please!",
        },
    });
    validate_result($result) or return;

    is $result->transaction->custom_fields->store_me, "please!", "stores custom field value";
};

subtest "Processor declined rejection" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => "2001.00",
        credit_card => credit_card(),
    });
    invalidate_result($result) or return;

    is($result->message, "Insufficient Funds");
    is($result->transaction->processor_response_code, "2001");
    is($result->transaction->processor_response_text, "Insufficient Funds");
    is($result->transaction->additional_processor_response, "2001 : Insufficient Funds");
};

subtest "billing_address_id" => sub {
    my $customer_result = WebService::Braintree::Customer->create();
    my $address_result = WebService::Braintree::Address->create({
        customer_id => $customer_result->customer->id,
        first_name => 'Jenna',
    });
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        customer_id => $customer_result->customer->id,
        billing_address_id => $address_result->address->id,
        credit_card => credit_card(),
    });
    validate_result($result) or return;

    is $result->transaction->billing_details->first_name, "Jenna";
};

subtest "with payment method nonce" => sub {
    subtest "it can create a transaction" => sub {
        my $cc_number = cc_number();
        my $nonce = WebService::Braintree::TestHelper::get_nonce_for_new_card($cc_number, '');

        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        is($result->transaction->credit_card_details->bin, cc_bin($cc_number));
    };

    subtest "apple pay" => sub {
        subtest "it can create a transaction with a fake apple pay nonce" => sub {
            plan skip_all => 'payment_method_nonce does not contain a valid payment instrument type';

            my $result = WebService::Braintree::Transaction->sale({
                amount => amount(40, 60),
                payment_method_nonce => WebService::Braintree::SandboxValues::Nonce->APPLE_PAY_VISA,
            });
            validate_result($result) or return;

            my $apple_pay_detail = $result->transaction->apple_pay;
            is($apple_pay_detail->card_type, WebService::Braintree::ApplePayCard::CardType::Visa);
            ok $apple_pay_detail->expiration_month + 0 > 0;
            ok $apple_pay_detail->expiration_year + 0 > 0;
            isnt($apple_pay_detail->cardholder_name, undef);
        };
    };
};

subtest "three_d_secure" => sub {
    plan skip_all => "three_d_secure doesn't work in the sandbox.";

    my $merchant_account_id = WebService::Braintree::TestHelper::THREE_D_SECURE_MERCHANT;

    subtest "can create a transaction with a three_d_secure_token" => sub {
        my $cc_number = cc_number();
        my $three_d_secure_token = WebService::Braintree::TestHelper::create_3ds_verification(
            $merchant_account_id, {
                number => $cc_number,
                expiration_month => "05",
                expiration_year => "2009",
            }
        );
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => {
                number => $cc_number,
                expiration_date => "05/09",
            },
            merchant_account_id => $merchant_account_id,
            three_d_secure_token => $three_d_secure_token,
        });
        validate_result($result) or return;
    };

    subtest "returns an error if three_d_secure_token is not a real one" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => cc_number(),
            merchant_account_id => $merchant_account_id,
            three_d_secure_token => "nonexistent_three_d_secure_token",
        });
        invalidate_result($result) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::Transaction::ThreeDSecureTokenIsInvalid;
        is($result->errors->for("transaction")->on("three_d_secure_token")->[0]->code, $expected_error_code);
    };

    subtest "returns an error if 3ds lookup data does not match transaction" => sub {
        my $three_d_secure_token = WebService::Braintree::TestHelper::create_3ds_verification(
            $merchant_account_id, {
                number => cc_number('visa'),
                expiration_month => "05",
                expiration_year => "2009",
            },
        );
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(80, 120),
            credit_card => credit_card({
                number => cc_number('visa'),
                expiration_date => "05/20",
            }),
            merchant_account_id => $merchant_account_id,
            three_d_secure_token => $three_d_secure_token,
        });
        invalidate_result($result) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::Transaction::ThreeDSecureTransactionDataDoesntMatchVerify;
        is($result->errors->for("transaction")->on("three_d_secure_token")->[0]->code, $expected_error_code);
    };
};

subtest "Service Fee" => sub {
    subtest "can create a transaction" => sub {
        my $svc_fee = amount(5, 15);
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_sub_merchant_account",
            credit_card => credit_card(),
            service_fee_amount => $svc_fee,
        });
        validate_result($result) or return;

        cmp_ok($result->transaction->service_fee_amount, '==', $svc_fee);
    };

    subtest "sub merchant account requires service fee" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_sub_merchant_account",
            credit_card => credit_card(),
        });
        invalidate_result($result) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::Transaction::SubMerchantAccountRequiresServiceFeeAmount;
        is($result->errors->for("transaction")->on("merchant_account_id")->[0]->code, $expected_error_code);
    };

    subtest "master merchant account does not support service fee" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_credit_card",
            credit_card => credit_card(),
            service_fee_amount => amount(5, 15),
        });
        invalidate_result($result) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::Transaction::ServiceFeeAmountNotAllowedOnMasterMerchantAccount;
        is($result->errors->for("transaction")->on("service_fee_amount")->[0]->code, $expected_error_code);
    };

    subtest "not allowed on credits" => sub {
        plan skip_all => 'sandbox_sub_merchant_account cannot create credits';

        my $result = WebService::Braintree::Transaction->credit({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_sub_merchant_account",
            credit_card => credit_card(),
            service_fee_amount => amount(5, 15),
        });
        invalidate_result($result) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::Transaction::ServiceFeeIsNotAllowedOnCredits;
        is($result->errors->for("transaction")->on("base")->[0]->code, $expected_error_code);
    };
};

subtest "create with hold in escrow" => sub {
    subtest "can successfully create new transcation with hold in escrow option" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_sub_merchant_account",
            credit_card => credit_card(),
            service_fee_amount => amount(5, 15),
            options => {
                hold_in_escrow => 'true',
            },
        });
        validate_result($result) or return;

        is($result->transaction->escrow_status, WebService::Braintree::Transaction::EscrowStatus::HoldPending);
    };

    subtest "fails to create new transaction with hold in escrow if merchant account is not submerchant"  => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_credit_card",
            credit_card => credit_card(),
            service_fee_amount => amount(5, 15),
            options => {
                hold_in_escrow => 'true',
            },
        });
        invalidate_result($result) or return;

        is(
            $result->errors->for("transaction")->on("base")->[0]->code,
            WebService::Braintree::ErrorCodes::Transaction::CannotHoldInEscrow,
        );
    }
};

subtest "Hold for escrow"  => sub {
    subtest "can hold a submerchant's authorized transaction for escrow" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_sub_merchant_account",
            credit_card => credit_card(),
            service_fee_amount => amount(5, 15),
        });
        my $hold_result = WebService::Braintree::Transaction->hold_in_escrow($result->transaction->id);
        validate_result($hold_result) or return;

        is($hold_result->transaction->escrow_status, WebService::Braintree::Transaction::EscrowStatus::HoldPending);
    };

    subtest "fails with an error when holding non submerchant account transactions for error" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_credit_card",
            credit_card => credit_card(),
        });
        my $hold_result = WebService::Braintree::Transaction->hold_in_escrow($result->transaction->id);
        invalidate_result($hold_result) or return;

        is($hold_result->errors->for("transaction")->on("base")->[0]->code,
            WebService::Braintree::ErrorCodes::Transaction::CannotHoldInEscrow,
        );
    };
};

subtest "Submit For Release" => sub {
    subtest "can submit escrowed transaction for release" => sub {
        plan skip_all => 'Cannot transition transaction to settled';

        my $response = WebService::Braintree::TestHelper::create_escrowed_transaction();
        my $result = WebService::Braintree::Transaction->release_from_escrow($response->transaction->id);
        validate_result($result) or return;

        is($result->transaction->escrow_status,
            WebService::Braintree::Transaction::EscrowStatus::ReleasePending,
        );
    };

    subtest "cannot submit non-escrowed transaction for release" => sub {
        my $sale = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            merchant_account_id => "sandbox_credit_card",
            credit_card => credit_card(),
        });
        my $result = WebService::Braintree::Transaction->release_from_escrow($sale->transaction->id);
        invalidate_result($result) or return;

        is($result->errors->for("transaction")->on("base")->[0]->code,
            WebService::Braintree::ErrorCodes::Transaction::CannotReleaseFromEscrow,
        );
    };
};

subtest "Cancel Release" => sub {
    plan skip_all => 'Cannot transition transaction to settled';

    subtest "can cancel release for a transaction which has been submitted" => sub {
        my $escrow = WebService::Braintree::TestHelper::create_escrowed_transaction();
        my $submit = WebService::Braintree::Transaction->release_from_escrow($escrow->transaction->id);
        my $result = WebService::Braintree::Transaction->cancel_release($submit->transaction->id);
        validate_result($result) or return;

        is($result->transaction->escrow_status, WebService::Braintree::Transaction::EscrowStatus::Held);
    };

    subtest "cannot cancel release of already released transactions" => sub {
        my $escrowed = WebService::Braintree::TestHelper::create_escrowed_transaction();
        my $result = WebService::Braintree::Transaction->cancel_release($escrowed->transaction->id);
        invalidate_result($result) or return;

        is($result->errors->for("transaction")->on("base")->[0]->code,
            WebService::Braintree::ErrorCodes::Transaction::CannotCancelRelease,
        );
    };
};

subtest "Security parameters" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        device_session_id => "abc123",
        fraud_merchant_id => "456",
        credit_card => credit_card(),
    });
    validate_result($result) or return;
};

subtest "Sale" => sub {
    subtest "returns payment instrument type" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            credit_card => {
                number => cc_number('visa'),
                expiration_date => "05/2009",
            },
        });
        validate_result($result) or return;

        my $transaction = $result->transaction;
        ok($transaction->payment_instrument_type eq WebService::Braintree::Transaction::PaymentInstrumentType::CREDIT_CARD);
    };

    subtest "returns payment instrument type for paypal" => sub {
        plan skip_all => "Error communicating with PayPal";
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce();
        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        my $transaction = $result->transaction;
        ok($transaction->payment_instrument_type eq WebService::Braintree::Transaction::PaymentInstrumentType::PAYPAL_ACCOUNT);
    };

    subtest "returns debug ID for paypal" => sub {
        plan skip_all => "Error communicating with PayPal";
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce();
        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        my $transaction = $result->transaction;
        isnt($transaction->paypal_details->debug_id, undef);
    };
};

subtest "Disbursement Details" => sub {
    subtest "disbursement_details for disbursed transactions" => sub {
        plan skip_all => "There is no id => 'deposittransaction'";

        my $result = WebService::Braintree::Transaction->find("deposittransaction");

        is $result->transaction->is_disbursed, 1;

        my $disbursement_details = $result->transaction->disbursement_details;
        is $disbursement_details->funds_held, 0;
        is $disbursement_details->disbursement_date, "2013-04-10T00:00:00Z";
        is $disbursement_details->success, 1;
        cmp_ok $disbursement_details->settlement_amount, '==', "100.00";
        is $disbursement_details->settlement_currency_iso_code, "USD";
        is $disbursement_details->settlement_currency_exchange_rate, "1";
    };

    subtest "is_disbursed false for non-disbursed transactions" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            credit_card => credit_card(),
        });

        is $result->transaction->is_disbursed, 0;
    };
};

subtest "Disputes" => sub {
    subtest "exposes disputes for disputed transactions" => sub {
        plan skip_all => "There is no id => 'disputedtransaction'";

        my $result = WebService::Braintree::Transaction->find("disputedtransaction");
        validate_result($result) or return;

        my $disputes = $result->transaction->disputes;
        my $dispute = shift(@$disputes);

        cmp_ok $dispute->amount, '==', '250.00';
        is $dispute->received_date, "2014-03-01T00:00:00Z";
        is $dispute->reply_by_date, "2014-03-21T00:00:00Z";
        is $dispute->reason, WebService::Braintree::Dispute::Reason::Fraud;
        is $dispute->status, WebService::Braintree::Dispute::Status::Won;
        is $dispute->currency_iso_code, "USD";
        is $dispute->transaction_details->id, "disputedtransaction";
        cmp_ok $dispute->transaction_details->amount, '==', "1000.00";
    };
};

subtest "Submit for Settlement" => sub {
    subtest "submit the full amount for settlement" => sub {
        my $amount = amount(40, 60);
        my $sale = WebService::Braintree::Transaction->sale({
            %$params,
            amount => $amount,
        });
        my $result = WebService::Braintree::Transaction->submit_for_settlement($sale->transaction->id);
        validate_result($result) or return;

        cmp_ok($result->transaction->amount, '==', $amount, "settlement amount");
        is($result->transaction->status, "submitted_for_settlement", "transaction submitted for settlement");
    };

    subtest "submit a lesser amount for settlement" => sub {
        my $sale = WebService::Braintree::Transaction->sale({
            %$params,
            amount => amount(40, 60),
        });
        my $settle_amount = amount(8, 12);
        my $result = WebService::Braintree::Transaction->submit_for_settlement($sale->transaction->id, $settle_amount);
        validate_result($result) or return;

        cmp_ok($result->transaction->amount, '==', $settle_amount, "settlement amount");
        is($result->transaction->status, "submitted_for_settlement", "transaction submitted for settlement");
    };

    subtest "can't submit a greater amount for settlement" => sub {
        my $amount = amount(40, 60);
        my $sale = WebService::Braintree::Transaction->sale({
            %$params,
            amount => $amount,
        });
        my $result = WebService::Braintree::Transaction->submit_for_settlement($sale->transaction->id, 2 * $amount);
        invalidate_result($result) or return;

        is($result->message, "Settlement amount is too large.");
    };
};

subtest "Refund" => sub {
    subtest "successful w/ partial refund amount" => sub {
        my $settled = create_settled_transaction({
            %$params,
            amount => amount(40, 60),
        });
        my $refund_amount = amount(10, 20);
        my $result = WebService::Braintree::Transaction->refund($settled->transaction->id, $refund_amount);
        validate_result($result) or return;

        is($result->transaction->type, 'credit', 'Refund result type is credit');
        cmp_ok($result->transaction->amount, '==', $refund_amount, "refund amount responds correctly");
    };

    subtest "unsuccessful if transaction has not been settled" => sub {
        plan skip_all => "Doesn't work right";
        my $sale = create_settled_transaction({
            %$params,
            amount => amount(40, 60),
        });
        my $result = WebService::Braintree::Transaction->refund($sale->transaction->id);
        invalidate_result($result) or return;

        is($result->message, "Cannot refund a transaction unless it is settled.", "Errors on unsettled transaction");
    };
};

subtest "Void" => sub {
    subtest "successful" => sub {
        my $sale = WebService::Braintree::Transaction->sale({
            %$params,
            amount => amount(40, 60),
        });
        my $void = WebService::Braintree::Transaction->void($sale->transaction->id);
        validate_result($void) or return;

        is($void->transaction->id, $sale->transaction->id, "Void tied to sale");
    };

    subtest "unsuccessful" => sub {
        my $settled = create_settled_transaction({
            %$params,
            amount => amount(40, 60),
        });
        my $void    = WebService::Braintree::Transaction->void($settled->transaction->id);
        invalidate_result($void) or return;

        is($void->message, "Transaction can only be voided if status is authorized, submitted_for_settlement, or - for PayPal - settlement_pending.");
    };
};

subtest "Find" => sub {
    subtest "successful" => sub {
        my $amount = amount(40, 60);
        my $sale_result = WebService::Braintree::Transaction->sale({
            %$params,
            amount => $amount,
        });
        my $find_result = WebService::Braintree::Transaction->find($sale_result->transaction->id);
        is $find_result->transaction->id, $sale_result->transaction->id, "should find existing transaction";
        cmp_ok $find_result->transaction->amount, '==', $amount, "should find correct amount";
    };

    subtest "unsuccessful" => sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::Transaction->find('foo');
        }, "Not Foound");
    };
};

subtest "Options" => sub {
    TODO: { local $TODO = "Returns 'settling', not 'submitted_for_settlement'";
    subtest "submit for settlement" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            credit_card => credit_card(),
            options  => {
                submit_for_settlement => 'true'
            },
        });
        is $result->transaction->status, "submitted_for_settlement", "should have correct status";
    };
    }

    subtest "store_in_vault" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(40, 60),
            credit_card => credit_card(),
            customer => {
                first_name => "Dan",
                last_name => "Smith",
            },
            billing => {
                street_address => "123 45 6",
            },
            shipping => {
                street_address => "789 10 11",
            },
            options  => {
                store_in_vault  => 'true',
                add_billing_address_to_payment_method => 'true',
                store_shipping_address_in_vault => 'true',
            },
        });

        my $customer_result = WebService::Braintree::Customer->find($result->transaction->customer->id);

        like $result->transaction->credit_card->token, qr/[\d\w]{4,}/, "it sets the token";
    };
};

subtest "Create from payment method token" => sub {
    my $sale_result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => credit_card(),
        customer => { first_name => "Dan", last_name => "Smith" },
        options  => { store_in_vault  => 'true' },
    });

    my $create_from_token = WebService::Braintree::Transaction->sale({
        customer_id => $sale_result->transaction->customer->id,
        payment_method_token => $sale_result->transaction->credit_card->token,
        amount => amount(5, 15),
    });
    validate_result($create_from_token) or return;

    is $create_from_token->transaction->customer->id, $sale_result->transaction->customer->id, "ties sale to existing customer";
    is $create_from_token->transaction->credit_card->token, $sale_result->transaction->credit_card->token, "ties sale to existing customer card";
};

subtest "Clone transaction" => sub {
    my $cc_number = cc_number();
    my $sale_result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => credit_card({
            number => $cc_number,
            expiration_date => '06/11',
        }),
        customer => {first_name => "Dan"},
        billing => {first_name => "Jim"},
        shipping => {first_name => "John"},
    });

    my $clone_amount = amount(100, 140);
    my $clone_result = WebService::Braintree::Transaction->clone_transaction($sale_result->transaction->id, {
        amount => $clone_amount,
        channel => "MyShoppingCartProvider",
        options => { submit_for_settlement => "false" },
    });
    validate_result($clone_result) or return;

    my $clone_transaction = $clone_result->transaction;

    isnt $clone_transaction->id, $sale_result->transaction->id;
    cmp_ok $clone_transaction->amount, '==', $clone_amount;
    is $clone_transaction->channel, "MyShoppingCartProvider";
    is $clone_transaction->credit_card->bin, cc_bin($cc_number);
    is $clone_transaction->credit_card->expiration_year, "2011";
    is $clone_transaction->credit_card->expiration_month, "06";
    is $clone_transaction->customer->first_name, "Dan";
    is $clone_transaction->billing->first_name, "Jim";
    is $clone_transaction->shipping->first_name, "John";
    is $clone_transaction->status, "authorized";
};

subtest "Clone transaction and submit for settlement" => sub {
    plan skip_all => "This is 'settling', not 'submitted_for_settlement'";

    my $sale_result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => credit_card(),
    });

    my $clone_amount = amount(100, 140);
    my $clone_result = WebService::Braintree::Transaction->clone_transaction($sale_result->transaction->id, {
        amount => $clone_amount,
        options => { submit_for_settlement => "true" },
    });
    validate_result($clone_result) or return;

    my $clone_transaction = $clone_result->transaction;

    is $clone_transaction->status, "submitted_for_settlement";
};

subtest "Clone transaction with validation error" => sub {
    plan skip_all => 'Transaction->credit() returns unauthorized';

    my $credit_result = WebService::Braintree::Transaction->credit({
        amount => amount(40, 60),
        credit_card => credit_card(),
    });
    validate_result($credit_result) or return;

    my $clone_result = WebService::Braintree::Transaction->clone_transaction(
        $credit_result->transaction->id, {amount => amount(100, 140)},
    );
    invalidate_result($clone_result) or return;

    my $expected_error_code = 91543;
    is($clone_result->errors->for("transaction")->on("base")->[0]->code, $expected_error_code);
};

subtest "Recurring" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        recurring => "true",
        credit_card => credit_card(),
    });
    validate_result($result) or return;

    is($result->transaction->recurring, 1);
};

subtest "Card Type Indicators" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => {
            number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Unknown,
            expiration_date => "05/12",
        },
    });
    validate_result($result) or return;

    is($result->transaction->credit_card->prepaid, WebService::Braintree::CreditCard::Prepaid::Unknown);
    is($result->transaction->credit_card->commercial, WebService::Braintree::CreditCard::Commercial::Unknown);
    is($result->transaction->credit_card->debit, WebService::Braintree::CreditCard::Debit::Unknown);
    is($result->transaction->credit_card->payroll, WebService::Braintree::CreditCard::Payroll::Unknown);
    is($result->transaction->credit_card->healthcare, WebService::Braintree::CreditCard::Healthcare::Unknown);
    is($result->transaction->credit_card->durbin_regulated, WebService::Braintree::CreditCard::DurbinRegulated::Unknown);
    is($result->transaction->credit_card->issuing_bank, WebService::Braintree::CreditCard::IssuingBank::Unknown);
    is($result->transaction->credit_card->country_of_issuance, WebService::Braintree::CreditCard::CountryOfIssuance::Unknown);
};

subtest "Venmo Sdk Payment Method Code" => sub {
    my $cc_number = WebService::Braintree::Test::VenmoSdk->VisaCreditCardNumber;
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        venmo_sdk_payment_method_code => WebService::Braintree::Test::VenmoSdk->VisaPaymentMethodCode,
    });
    validate_result($result) or return;

    is($result->transaction->credit_card->bin, cc_bin($cc_number));
    is($result->transaction->credit_card->last_4, cc_last4($cc_number));
};

subtest "Venmo Sdk Session" => sub {
    my $result = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        credit_card => credit_card(),
        options => {
            venmo_sdk_session => WebService::Braintree::Test::VenmoSdk::Session,
        },
    });
    validate_result($result) or return;

    ok $result->transaction->credit_card->venmo_sdk;
};

subtest "paypal" => sub {
    subtest "create a transaction with a one-time paypal nonce" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(5, 15),
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        isnt($result->transaction->paypal_details, undef);
        isnt($result->transaction->paypal_details->payer_email, undef);
        isnt($result->transaction->paypal_details->payment_id, undef);
        isnt($result->transaction->paypal_details->authorization_id, undef);
        isnt($result->transaction->paypal_details->image_url, undef);
        isnt($result->transaction->paypal_details->debug_id, undef);
    };

    subtest "create a transaction with a payee email" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(5, 15),
            payment_method_nonce => $nonce,
            paypal_account => {
                payee_email => 'payee@example.com',
            },
        });
        validate_result($result) or return;

        isnt($result->transaction->paypal_details, undef);
        isnt($result->transaction->paypal_details->payer_email, undef);
        isnt($result->transaction->paypal_details->payment_id, undef);
        isnt($result->transaction->paypal_details->authorization_id, undef);
        isnt($result->transaction->paypal_details->image_url, undef);
        isnt($result->transaction->paypal_details->debug_id, undef);
        is($result->transaction->paypal_details->payee_email, "payee\@example.com");
    };

    subtest "create a transaction with a payee email in the options params" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(5, 15),
            payment_method_nonce => $nonce,
            paypal_account => {
            },
            options => {
                payee_email => "payee\@example.com",
            },
        });
        validate_result($result) or return;

        isnt($result->transaction->paypal_details, undef);
        isnt($result->transaction->paypal_details->payer_email, undef);
        isnt($result->transaction->paypal_details->payment_id, undef);
        isnt($result->transaction->paypal_details->authorization_id, undef);
        isnt($result->transaction->paypal_details->image_url, undef);
        isnt($result->transaction->paypal_details->debug_id, undef);
        is($result->transaction->paypal_details->payee_email, "payee\@example.com");
    };

    subtest "create a transaction with a one-time paypal nonce and vault" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_one_time_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
            options => {
                store_in_vault => "true",
            },
        });
        validate_result($result) or return;

        my $transaction = $result->transaction;
        isnt($transaction->paypal_details, undef);
        isnt($transaction->paypal_details->payer_email, undef);
        isnt($transaction->paypal_details->payment_id, undef);
        isnt($transaction->paypal_details->authorization_id, undef);
        is($transaction->paypal_details->token, undef);
        isnt($transaction->paypal_details->debug_id, undef);
    };

    subtest "create a transaction with a future payment paypal nonce and vault" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_future_payment_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
            options => {
                store_in_vault => "true",
            },
        });
        validate_result($result) or return;

        my $transaction = $result->transaction;
        isnt($transaction->paypal_details, undef);
        isnt($transaction->paypal_details->payer_email, undef);
        isnt($transaction->paypal_details->payment_id, undef);
        isnt($transaction->paypal_details->authorization_id, undef);
        isnt($transaction->paypal_details->token, undef);
        isnt($transaction->paypal_details->debug_id, undef);
    };

    subtest "void paypal transaction" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_future_payment_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        my $void_result = WebService::Braintree::Transaction->void($result->transaction->id);
        validate_result($void_result) or return;
    };

    subtest "submit paypal transaction for settlement" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_future_payment_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
        });
        validate_result($result) or return;

        my $settlement_result = WebService::Braintree::Transaction->submit_for_settlement($result->transaction->id);
        validate_result($settlement_result) or return;

        ok $settlement_result->transaction->status eq WebService::Braintree::Transaction::Status::Settling;
    };

    subtest "refund a paypal transaction" => sub {
        my $nonce = WebService::Braintree::TestHelper::generate_future_payment_paypal_nonce('');
        isnt($nonce, undef);

        my $result = WebService::Braintree::Transaction->sale({
            amount => WebService::Braintree::SandboxValues::TransactionAmount::AUTHORIZE,
            payment_method_nonce => $nonce,
            options => {
                submit_for_settlement => "true",
            },
        });
        validate_result($result) or return;

        my $id = $result->transaction->id;

        my $refund_result = WebService::Braintree::Transaction->refund($id);
        validate_result($refund_result) or return;
    };

    subtest "paypal transaction returns settlement response code" => sub {
        my $result = WebService::Braintree::Transaction->sale({
            amount => amount(5, 15),
            payment_method_nonce => WebService::Braintree::SandboxValues::Nonce->PAYPAL_FUTURE_PAYMENT,
            options => {
                submit_for_settlement => "true",
            },
        });
        validate_result($result) or return;

        WebService::Braintree::TestHelper::settlement_decline($result->transaction->id);

        $result = WebService::Braintree::Transaction->find($result->transaction->id);
        validate_result($result) or return;

        my $transaction = $result->transaction;
        is($transaction->status, WebService::Braintree::Transaction::Status::SettlementDeclined);
        is($transaction->processor_settlement_response_code, "4001");
        is($transaction->processor_settlement_response_text, "Settlement Declined");
    };
};

subtest update_details => sub {
    plan skip_all => 'update_details() returns unauthorized for some reason';

    my $amount = amount(40, 60);
    my $txn_result = WebService::Braintree::Transaction->sale({
        %$params,
        amount => $amount,
        order_id => '123',
        descriptor => {
            name => '123*123456789012345678',
            phone => '3334445555',
            url => 'ebay.com',
        },
    });
    validate_result($txn_result) or return;

    subtest 'when status is NOT submitted_for_settlement' => sub {
        my $result = WebService::Braintree::Transaction->update_details(
            $txn_result->transaction->id, {
                amount => $amount - 1,
                order_id => '456',
                descriptor => {
                    name => '456*123456789012345678',
                    phone => '3334445555',
                    url => 'ebay.com',
                },
            },
        );
        invalidate_result($result) or return;
        is($result->errors->for('transaction')->on('base')->[0]->code, WebService::Braintree::ErrorCodes::Transaction::CannotUpdateTransactionDetailsNotSubmittedForSettlement);
    };

    subtest 'when status is submitted_for_settlement' => sub {
        my $submit = WebService::Braintree::Transaction->submit_for_settlement($txn_result->transaction->id);
        validate_result($submit) or return;
        settle($txn_result->transaction->id);

        subtest 'successfully update details' => sub {
            my $result = WebService::Braintree::Transaction->update_details(
                $txn_result->transaction->id, {
                    amount => $amount - 1,
                    order_id => '456',
                    descriptor => {
                        name => '456*123456789012345678',
                        phone => '3334445555',
                        url => 'ebay.com',
                    },
                },
            );
            validate_result($result) or return;

            my $txn = $result->transaction;
            cmp_ok($txn->amount, '==', $amount - 1);
            is($txn->order_id, '456');
            is($txn->descriptor->name, '456*123456789012345678');
        };

        subtest 'raises an error when a key is invalid' => sub {
        };

        subtest 'Raises an error' => sub {
            subtest 'when settlement amount is invalid' => sub {
            };

            subtest 'when the descriptor is invalid' => sub {
            };

            subtest 'when the order_id is invalid' => sub {
            };

            subtest 'on an unsupported processor' => sub {
            };
        };
    };
};

subtest submit_for_partial_settlement => sub {
    plan skip_all => 'submit_for_partial_settlement() returns unauthorized for some reason';

    subtest "returns an error with an order_id that's too long" => sub {
        my $amount = amount(40, 60);
        my $txn_result = WebService::Braintree::Transaction->sale({
            %$params,
            amount => $amount,
            merchant_account_id => 'sandbox_credit_card',
        });
        validate_result($txn_result) or return;

        my $result = WebService::Braintree::Transaction->submit_for_partial_settlement(
            $txn_result->transaction->id,
            20, {
                order_id => '1'x256,
            },
        );
        invalidate_result($result) or return;
        is($result->errors->for('transaction')->on('order_id')->[0]->code, WebService::Braintree::ErrorCodes::Transaction::OrderIdIsTooLong);
    };
};

done_testing();
