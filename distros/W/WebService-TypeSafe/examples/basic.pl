#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use WebService::TypeSafe qw(choice noul score);

my $api_key = $ENV{TYPESAFE_API_KEY}
    or die "Set TYPESAFE_API_KEY for this example\n";

# Applications can obtain this value from any configuration or secret store.
my $client = WebService::TypeSafe->new(api_key => $api_key);
my $result = $client->system_one(
    state => { message => 'Help! My payouts have failed for three days.' },
    questions => {
        urgent => noul(instructions => 'Does `message` convey urgency?'),
        department => choice(
            instructions => 'Which team should handle `message`?',
            criteria => {
                billing => 'Payments, invoicing, and refunds',
                technical => 'Bugs, outages, and integrations',
                other => undef,
            },
        ),
        frustration => score(
            instructions => 'How frustrated is the customer in `message`?',
            criteria => ['Calm', 'Concerned', 'Very angry'],
        ),
    },
);

say 'urgent probability: ', $result->nouls->{urgent}->noul;
say 'department: ', $result->choices->{department}->choice;
say 'frustration: ', $result->scores->{frustration}->score;
