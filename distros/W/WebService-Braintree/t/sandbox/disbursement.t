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

my $disbursement_params = {
    id => "123456",
    merchant_account => {
        id => "sandbox_sub_merchant_account",
        master_merchant_account => {
            id => "sandbox_master_merchant_account",
            status => "active"
        },
        status => "active"
    },
    transaction_ids => ["sub_merchant_transaction"],
    amount => "100.00",
    disbursement_date => WebService::Braintree::TestHelper::parse_datetime("2014-04-10 00:00:00"),
    exception_message => "invalid_account_number",
    follow_up_action => "update",
    retry => "false",
    success => "false",
};

subtest "Transactions" => sub {
    subtest "retrieves transactions associated with the disbursement" => sub {
        plan skip_all => 'sandbox_sub_merchant_account is unauthorized';

        my $disbursement = WebService::Braintree::Disbursement->new($disbursement_params);
        my $transactions = $disbursement->transactions();
        isnt $transactions, undef;

        is($transactions->first()->id(), "sub_merchant_transaction");
    };
};

done_testing();
