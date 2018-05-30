#!/usr/bin/env perl

use Test::Spec::Acceptance;

Feature "Test::Spec::Acceptance tests module" => sub {
    Scenario "Usage example" => sub {
        my ($number, $accumulated);

        Given "a relevant number" => sub {
            $number = 42;
        };
        When "we add 0 to it" => sub {
            $accumulated = $number + 0
        };
        When "we add 0 again" => sub {
            $accumulated = $number + 0
        };
        Then "it does not change it's value" => sub {
            is($accumulated, 42);
        };
    };
};

runtests;
