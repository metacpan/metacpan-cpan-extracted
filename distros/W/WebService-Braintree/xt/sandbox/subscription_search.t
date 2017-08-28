#!/usr/bin/env perl
use lib qw(lib t/lib);
use Test::More;
use Time::HiRes qw(gettimeofday);
use WebService::Braintree;
use WebService::Braintree::Util;
use WebService::Braintree::TestHelper qw(sandbox);

my $customer = WebService::Braintree::Customer->create({first_name => "Fred", last_name => "Fredson"});
my $card = WebService::Braintree::CreditCard->create({number => "5431111111111111", expiration_date => "05/12", customer_id => $customer->customer->id});

subtest "id (equality)" => sub {
    my $id = generate_unique_integer() . "123";
    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription1_$id"
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription2_$id"
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
                                                                        my $search = shift;
                                                                        $search->id->is("subscription1_$id");
                                                                    });
  TODO: {
        todo_skip "Tests consistently fail in sandbox environment", 2;
        ok grep { $_ eq $subscription1->id } @{$search_result->ids};
        not_ok grep { $_ eq $subscription2->id } @{$search_result->ids};
    }
    ;
};

subtest "price (range)" => sub {
    my $id = generate_unique_integer() . "223";

    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription1_$id",
        price => "5.00"
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription2_$id",
        price => "6.00"
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
                                                                        my $search = shift;
                                                                        $search->price->max("5.50");
                                                                    });

  TODO: {
        todo_skip "Tests consistently fail in sandbox environment", 2;
        ok grep { $_ eq $subscription1->id } @{search_result->ids};
        not_ok grep { $_ eq $subscription2->id } @{search_result->ids};
    }
    ;
};

subtest "price (is)"  => sub {
    my $id = generate_unique_integer() . "223";

    my $subscription1 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription1_$id",
        price => "5.00"
    })->subscription;

    my $subscription2 = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription2_$id",
        price => "6.00"
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub {
                                                                        my $search = shift;
                                                                        $search->price->is("5.00");
                                                                    });

  TODO: {
        todo_skip "Tests consistently fail in sandbox environment", 2;
        ok grep { $_ eq $subscription1->id } @{search_result->ids};
        not_ok grep { $_ eq $subscription2->id } @{search_result->ids};
    }
    ;
};

subtest "status (multiple value)" => sub {
    my $id = generate_unique_integer() . "222";

    my $subscription_active = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription1_$id"
    })->subscription;

    my $subscription_past_due = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription2_$id"
    })->subscription;

  TODO: {
        todo_skip "Tests consistently fail in sandbox environment", 2;

        make_subscription_past_due($subscription_past_due->id);

        my $search_result = WebService::Braintree::Subscription->search(sub {
                                                                            my $search = shift;
                                                                            $search->status->is("Active");
                                                                        });

        ok grep { $_ eq $subscription_active->id } @{search_result->ids};
        not_ok grep { $_ eq $subscription_past_due->id } @{search_result->ids};
    }
    ;
};

subtest "each (single value)" => sub {
    my $id = generate_unique_integer() . "single_value";

    my $subscription_active = WebService::Braintree::Subscription->create({
        payment_method_token => $card->credit_card->token,
        plan_id => "integration_trialless_plan",
        id => "subscription1_$id"
    })->subscription;

    my $search_result = WebService::Braintree::Subscription->search(sub{
                                                                        shift->id->is("subscription1_$id");
                                                                    });

    my @subscriptions = ();
    $search_result->each(sub {
                             push(@subscriptions, shift);
                         });

  TODO: {
        todo_skip "Tests consistently fail in sandbox environment", 1;
        is_deeply \@subscriptions, [$subscription_active];
    }
    ;
};

subtest "merchant_account_id" => sub {
    subtest "bogus id" => sub {
        my $id = generate_unique_integer() . "single_value";
        my $subscription_active = WebService::Braintree::Subscription->create({
            payment_method_token => $card->credit_card->token,
            plan_id => "integration_trialless_plan",
            id => "subscription1_$id"
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
            plan_id => "integration_trialless_plan",
            id => "subscription1_$id"
        })->subscription;

      TODO: {
            todo_skip "Tests consistently fail in sandbox environment", 1;

            my $search_result = WebService::Braintree::Subscription->search(sub{
                                                                                my $search = shift;
                                                                                $search->id->is("subscription1_$id");
                                                                                $search->merchant_account_id->in("obvious_junk", $subscription_active->merchant_account_id);
                                                                            });

            is scalar @{$search_result->ids}, 1;
        }
        ;
    };

    subtest "valid id" => sub {
        my $id = generate_unique_integer() . "single_value";
        my $subscription_active = WebService::Braintree::Subscription->create({
            payment_method_token => $card->credit_card->token,
            plan_id => "integration_trialless_plan",
            id => "subscription1_$id"
        })->subscription;

      TODO: {
            todo_skip "Tests consistently fail in sandbox environment", 1;

            my $search_result = WebService::Braintree::Subscription->search(sub{
                                                                                my $search = shift;
                                                                                $search->id->is("subscription1_$id");
                                                                                $search->merchant_account_id->is($subscription_active->merchant_account_id);
                                                                            });

            is scalar @{$search_result->ids}, 1;
        }
        ;
    };
};

TODO: {
    todo_skip "Tests consistently fail in sandbox environment", 1;

    subtest "all" => sub {
        my $subscriptions = WebService::Braintree::Subscription->all;
        ok scalar @{$subscriptions->ids} > 1;
    };
}
;

sub generate_unique_integer {
    return int(gettimeofday * 1000);
}

done_testing();
