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

subtest "returns an empty collection if there is no data" => sub {
    my $settlement_date = '2011-01-01';
    my $result = WebService::Braintree::SettlementBatchSummary->generate($settlement_date);

    is($result->is_success, 1);
    is(scalar @{$result->settlement_batch_summary->records}, 0);
};

subtest "returns an error if the result cannot be parsed" => sub {
    my $settlement_date = 'NOT A DATE';
    my $result = WebService::Braintree::SettlementBatchSummary->generate($settlement_date);

    ok(!$result->is_success);
    is($result->message, 'Settlement Date is invalid');
};

subtest "returns transactions settled on a given day" => sub {
    plan skip_all => "Unclear why this isn't working anymore.";

    my $transaction_params = {
        amount => "54.12",
        credit_card => {
            number => "5431111111111111",
            expiration_date => "05/12",
        },
    };

    my $settlement_date = WebService::Braintree::TestHelper::now_in_eastern;
    my $transaction = create_settled_transaction($transaction_params);

    my $result = WebService::Braintree::SettlementBatchSummary->generate($settlement_date);

    is($result->is_success, 1);

    my @mastercard_records = grep {
        $_->{card_type} eq 'MasterCard'
    } @{$result->settlement_batch_summary->records};

    ok($mastercard_records[0]->{count} >= 1);
    ok($mastercard_records[0]->{amount_settled} >= $transaction_params->{amount});
};

# This looks like it depends on other tests being successful?
subtest "returns transactions grouped by custom field" => sub {
    plan skip_all => "Still not working, even with custom field added";

    my $transaction_params = {
        amount => "50.00",
        credit_card => {
            number => "5431111111111111",
            expiration_date => "05/12"
        },
        custom_fields => {
            store_me => "custom_value",
        },
    };

    my $settlement_date = WebService::Braintree::TestHelper::now_in_eastern;
    my $transaction = create_settled_transaction($transaction_params);

    my $result = WebService::Braintree::SettlementBatchSummary->generate($settlement_date, "store_me");

    is($result->is_success, 1);

    my @mastercard_records = grep {
        $_->{store_me} eq 'custom_value' && $_->{card_type} eq 'MasterCard'
    } @{$result->settlement_batch_summary->records};

    ok($mastercard_records[0]->{count} >= 1);
    ok($mastercard_records[0]->{amount_settled} >= $transaction_params->{amount});
};

done_testing();
