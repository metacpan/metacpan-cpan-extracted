# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use HTTP::Request;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);

use WebService::Braintree;
use WebService::Braintree::Util qw(hash_to_query_string);
use WebService::Braintree::TestHelper qw(sandbox);

subtest "gets the right transaction data" => sub {
    my $amount = amount(40, 60);
    my $tr_params = {
        redirect_url => "http://example.com",
        transaction => {
            type => "sale",
            amount => $amount,
        },
    };

    my $transaction_params = {
        transaction => {
            credit_card => credit_card(),
        },
    };

    my $tr_data = WebService::Braintree::TransparentRedirect->transaction_data($tr_params);
    my $query_string_response = simulate_form_post_for_tr($tr_data, $transaction_params);
    my $result = WebService::Braintree::TransparentRedirect->confirm($query_string_response);
    validate_result($result) or return;

    my $transaction = $result->transaction;
    is $transaction->type, "sale", "type should be sale";
    cmp_ok $transaction->amount, '==', $amount, "amount should be $amount";
};

subtest "create customer data" => sub {
    my $customer_create_tr_params = {redirect_url => "http://example.com"};
    my $customer_params = {
        customer => {
            first_name => "Sally",
            last_name  => "Sitwell",
        },
    };

    my $tr_data = WebService::Braintree::TransparentRedirect->create_customer_data($customer_create_tr_params);
    my $query_string_response = simulate_form_post_for_tr($tr_data, $customer_params);
    my $result = WebService::Braintree::TransparentRedirect->confirm($query_string_response);
    validate_result($result) or return;

    isnt($result->customer->id, undef) or return;
    is $result->customer->first_name, "Sally", "First name is accepted";
    is $result->customer->last_name, "Sitwell", "Last name is accepted";
};

subtest "update customer" => sub {
    my $customer = WebService::Braintree::Customer->new();
    my $create = $customer->create({first_name => "Gob", last_name => "Bluth"});
    my $customer_update_tr_params = {redirect_url => "http://example.com", customer_id => $create->customer->id};
    my $customer_update_params = {
        customer => {
            first_name => "Steve",
            last_name => "Holt",
        },
    };

    my $tr_data = WebService::Braintree::TransparentRedirect->update_customer_data($customer_update_tr_params);
    my $query_string_response = simulate_form_post_for_tr($tr_data, $customer_update_params);
    my $result = WebService::Braintree::TransparentRedirect->confirm($query_string_response);
    validate_result($result) or return;

    isnt($result->customer, undef) or return
    is $result->customer->first_name, "Steve", "changes customer first name";
    is $result->customer->last_name, "Holt", "changes customer last name";
};

subtest "credit card data" => sub {
    my $customer = WebService::Braintree::Customer->new();
    my $create_customer = $customer->create({first_name => "Judge", last_name => "Reinhold"});

    my $cc_number = cc_number();
    my $expiration = '05/12';
    my $credit_card_create_tr_params = {
        redirect_url => "http://example.com",
        credit_card => {
            number => $cc_number,
            customer_id => $create_customer->customer->id,
        },
    };
    my $credit_card_create_params = {
        credit_card => credit_card({
            number => $cc_number,
            expiration_date => $expiration,
        }),
    };

    my $tr_data = WebService::Braintree::TransparentRedirect->create_credit_card_data($credit_card_create_tr_params);
    my $query_string_response = simulate_form_post_for_tr($tr_data, $credit_card_create_params);
    my $result = WebService::Braintree::TransparentRedirect->confirm($query_string_response);
    validate_result($result) or return;

    subtest "result credit card" => sub {
        isnt($result->credit_card, undef) or return;
        is $result->credit_card->last_4, cc_last4($cc_number), "sets card #";
        is $result->credit_card->expiration_month, "05", "sets expiration date";
    };

    subtest "update existing" => sub {
        my $credit_card_update_tr_params = { redirect_url => "http://example.com", payment_method_token => $result->credit_card->token };
        my $credit_card_create_params = {
            credit_card => {
                number => "4009348888881881",
                expiration_date => "09/2013",
            },
        };

        my $update_tr_data = WebService::Braintree::TransparentRedirect->update_credit_card_data($credit_card_update_tr_params);
        my $update_response = simulate_form_post_for_tr($update_tr_data, $credit_card_create_params);
        my $update_result = WebService::Braintree::TransparentRedirect->confirm($update_response);
        validate_result($update_result) or return;

        isnt($update_result->credit_card, undef) or return;
        is $update_result->credit_card->last_4, "1881", "Card number was updated";
        is $update_result->credit_card->expiration_month, "09", "Card exp month was updated";
    };
};

done_testing();

sub simulate_form_post_for_tr {
    my ($tr_string, $form_params) = @_;
    my $escaped_tr_string = uri_escape($tr_string);
    my $tr_data = {tr_data => $escaped_tr_string, %$form_params};

    my $request = HTTP::Request->new(
        POST => WebService::Braintree->configuration->base_merchant_url . '/transparent_redirect_requests',
    );

    $request->content_type('application/x-www-form-urlencoded');
    $request->content(hash_to_query_string($tr_data));

    my $agent = LWP::UserAgent->new;
    my $response = $agent->request($request);
    my @url_and_query = split(/\?/, $response->header('location'), 2);
    return $url_and_query[1];
}
