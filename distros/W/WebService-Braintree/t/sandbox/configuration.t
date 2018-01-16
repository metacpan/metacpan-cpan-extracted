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

subtest "default integration configuration" => sub {
    my $config = WebService::Braintree::TestHelper->config;

    my $amount = amount(5, 15);
    my $result = WebService::Braintree::Transaction->sale({
        amount => $amount,
        credit_card => credit_card(),
    });
    validate_result($result) or return;

    cmp_ok $result->transaction->amount, '==', $amount;
};

subtest "configuration two" => sub {
    my $config = WebService::Braintree::Configuration->new;

    $config->environment("sandbox");
    $config->public_key("it_should_explode");
    $config->merchant_id(WebService::Braintree::TestHelper->config->merchant_id);
    $config->private_key("with_these_values");

    my $gateway = $config->gateway;
    should_throw("AuthenticationError", sub {
        $gateway->transaction->create({
            type => "sale",
            amount => amount(5, 15),
        });
    });
};

done_testing();
