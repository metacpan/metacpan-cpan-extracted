#!/usr/bin/env perl
use lib qw(lib t/lib);
use Test::More;
use Time::HiRes qw(gettimeofday);
use WebService::Braintree;
use WebService::Braintree::TestHelper qw(sandbox);
use WebService::Braintree::CreditCardNumbers::CardTypeIndicators;

my $customer_create = WebService::Braintree::Customer->create({first_name => "Walter", last_name => "Weatherman"});

subtest "card verification is returned by result objects" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "4000111111111115",
        expiration_date => "12/15",
        options => {
            verify_card => 1
        }
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    my $verification = $result->credit_card_verification;

    is $verification->credit_card->{'last_4'}, "1115";
    is $verification->status, "processor_declined";
};

subtest "finds credit card verification" => sub {
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => "4000111111111115",
        expiration_date => "12/15",
        options => {
            verify_card => 1
        }
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);
    my $verification = $result->credit_card_verification;

    my $find_result = WebService::Braintree::CreditCardVerification->find($verification->id);

    is $find_result->id, $verification->id;
};

subtest "Card Type Indicators" => sub {
    my $cardholder_name = "Tom Smith" . gettimeofday;
    my $credit_card_params = {
        customer_id => $customer_create->customer->id,
        number => WebService::Braintree::CreditCardNumbers::CardTypeIndicators::Unknown,
        expiration_date => "12/15",
        cardholder_name => $cardholder_name,
        options => {
            verify_card => 1
        }
    };

    my $result = WebService::Braintree::CreditCard->create($credit_card_params);

    my $search_results = WebService::Braintree::CreditCardVerification->search( sub {
                                                                                    my $search = shift;
                                                                                    $search->credit_card_cardholder_name->is($cardholder_name);
                                                                                });

    is $search_results->maximum_size, 1;
    my $credit_card = $search_results->first->credit_card;

    is($credit_card->{'prepaid'}, WebService::Braintree::CreditCard::Prepaid::Unknown);
    is($credit_card->{'commercial'}, WebService::Braintree::CreditCard::Commercial::Unknown);
    is($credit_card->{'debit'}, WebService::Braintree::CreditCard::Debit::Unknown);
    is($credit_card->{'payroll'}, WebService::Braintree::CreditCard::Payroll::Unknown);
    is($credit_card->{'healthcare'}, WebService::Braintree::CreditCard::Healthcare::Unknown);
    is($credit_card->{'durbin_regulated'}, WebService::Braintree::CreditCard::DurbinRegulated::Unknown);
    is($credit_card->{'issuing_bank'}, WebService::Braintree::CreditCard::IssuingBank::Unknown);
    is($credit_card->{'country_of_issuance'}, WebService::Braintree::CreditCard::CountryOfIssuance::Unknown);
};

done_testing();
