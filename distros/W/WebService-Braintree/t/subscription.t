#!/usr/bin/env perl
use lib qw(lib t/lib);
use WebService::Braintree;
use Test::More;
use Test::Moose;
use WebService::Braintree::TestHelper;


subtest "does have correct attributes" => sub {
    my $subscription = WebService::Braintree::Subscription->new(balance => "12.00");

    is $subscription->balance, "12.00";
    has_attribute_ok $subscription, "balance";
};

subtest "throws NotFoundError if find is given empty string" => sub {
    should_throw("NotFoundError", sub { WebService::Braintree::Subscription->find("") });
    should_throw("NotFoundError", sub { WebService::Braintree::Subscription->find("  ") });
};

done_testing();
