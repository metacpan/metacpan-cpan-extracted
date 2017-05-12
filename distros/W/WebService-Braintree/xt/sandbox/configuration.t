#!/usr/bin/env perl
use lib qw(lib t/lib);
use Test::More;
use WebService::Braintree;
use WebService::Braintree::TestHelper qw(sandbox);

subtest "default integration configuration" => sub {
    my $config = WebService::Braintree::TestHelper->config;

    my $result = WebService::Braintree::Transaction->sale({
        amount => "10.00",
        credit_card => {
            number => "5431111111111111",
            expiration_date => "05/12"
        }});

    ok $result->is_success;
    is $result->transaction->amount, "10.00";
};

subtest "configuration two" => sub {

    my $config = WebService::Braintree::Configuration->new;
    $config->environment("sandbox");
    $config->public_key("it_should_explode");
    $config->merchant_id(WebService::Braintree::TestHelper->config->merchant_id);
    $config->private_key("with_these_values");
    my $gateway = $config->gateway;
    should_throw("AuthenticationError", sub { $gateway->transaction->create({type => "sale", amount => "10.00"}) });
};

done_testing();
