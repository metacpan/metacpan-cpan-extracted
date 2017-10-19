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
use WebService::Braintree::Util;
use WebService::Braintree::TestHelper qw(sandbox);

WebService::Braintree::TestHelper->verify_sandbox
    || BAIL_OUT 'Sandbox is not prepared properly. Please read xt/README.';

my $customer = WebService::Braintree::Customer->create({
    first_name => "Fred",
    last_name => "Fredson",
});

my $card = WebService::Braintree::CreditCard->create({
    number => "5431111111111111",
    expiration_date => "05/12",
    customer_id => $customer->customer->id,
});

subtest "id (equality)" => sub {
    my $id = generate_unique_integer() . "123";
    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription1_$id",
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription2_$id",
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
        my $search = shift;
        $search->id->is("subscription1_$id");
    });

    ok grep { $_ eq $subscription1->id } @{$search_result->ids};
    not_ok grep { $_ eq $subscription2->id } @{$search_result->ids};
};

subtest "price (range)" => sub {
    my $id = generate_unique_integer() . "223";

    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription1_$id",
        price => "5.00",
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription2_$id",
        price => "6.00",
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
        my $search = shift;
        $search->price->max("5.50");
    });

    ok grep { $_ eq $subscription1->id } @{$search_result->ids};
    not_ok grep { $_ eq $subscription2->id } @{$search_result->ids};
};

subtest "price (is)"  => sub {
    my $id = generate_unique_integer() . "223";

    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription1_$id",
        price => "5.00",
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription2_$id",
        price => "6.00",
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
        my $search = shift;
        $search->price->is("5.00");
    });

    ok grep { $_ eq $subscription1->id } @{$search_result->ids};
    not_ok grep { $_ eq $subscription2->id } @{$search_result->ids};
};

subtest "status (multiple value)" => sub {
    plan skip_all => "make_subscription_past_due receives a 404";

    my $id = generate_unique_integer() . "222";

    my $subscription_active = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription1_$id",
    })->subscription;

    my $subscription_past_due = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription2_$id",
    })->subscription;

    make_subscription_past_due($subscription_past_due->id);

    my $search_result = WebService::Braintree::Subscription->search(sub {
        my $search = shift;
        $search->status->is("Active");
    });

    ok grep { $_ eq $subscription_active->id } @{$search_result->ids};
    not_ok grep { $_ eq $subscription_past_due->id } @{$search_result->ids};
};

subtest "each (single value)" => sub {
    my $id = generate_unique_integer() . "single_value";

    my $subscription_active = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
        id => "subscription1_$id",
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub{
        shift->id->is("subscription1_$id");
    });

    my @subscriptions = ();
    $search_result->each(sub {
        push(@subscriptions, shift);
    });
    is_deeply \@subscriptions, [$subscription_active];
};

subtest "merchant_account_id" => sub {
    subtest "bogus id" => sub {
        my $id = generate_unique_integer() . "single_value";
        my $subscription_active = WebService::Braintree::Subscription->create({
            payment_method_token => $card->credit_card->token,
            plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
            id => "subscription1_$id",
        })->subscription;

        my $search_result = WebService::Braintree::Subscription->search(sub{
            my $search = shift;
            $search->id->is("subscription1_$id");
            $search->merchant_account_id->is("obvious_junk");
        });

        is scalar @{$search_result->ids}, 0;
    };

    subtest "mixed bogus and valid id" => sub {
        my $id = generate_unique_integer() . "single_value";
        my $subscription_active = WebService::Braintree::Subscription->create({
            payment_method_token => $card->credit_card->token,
            plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
            id => "subscription1_$id",
        })->subscription;

        my $search_result = WebService::Braintree::Subscription->search(sub{
            my $search = shift;
            $search->id->is("subscription1_$id");
            $search->merchant_account_id->in("obvious_junk", $subscription_active->merchant_account_id);
        });

        is scalar @{$search_result->ids}, 1;
    };

    subtest "valid id" => sub {
        my $id = generate_unique_integer() . "single_value";
        my $subscription_active = WebService::Braintree::Subscription->create({
            payment_method_token => $card->credit_card->token,
            plan_id => WebService::Braintree::TestHelper->TRIALLESS_PLAN_ID,
            id => "subscription1_$id",
        })->subscription;

        my $search_result = WebService::Braintree::Subscription->search(sub{
            my $search = shift;
            $search->id->is("subscription1_$id");
            $search->merchant_account_id->is($subscription_active->merchant_account_id);
        });

        is scalar @{$search_result->ids}, 1;
    };
};

subtest "all" => sub {
    my $subscriptions = WebService::Braintree::Subscription->all;
    ok scalar @{$subscriptions->ids} > 1;
};

done_testing();
