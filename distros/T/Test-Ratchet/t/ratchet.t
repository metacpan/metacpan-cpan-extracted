#!perl

use strict;
use warnings;
use feature 'state';
use Test::Ratchet qw(ratchet);
use Test::More;

my $ratchet = ratchet(
    \&one,
    \&two,
    3 => \&three_four_five,
    '*' => \&indefinite,
    \&fail_if_called
);

my $inc = 0;

$inc++; $ratchet->($inc);
$inc++; $ratchet->($inc, 'test');

for (1,2,3) {
    $inc++; $ratchet->();
}

for ( 0 .. (rand() * 20) ) {
    $inc++; $ratchet->();
}

done_testing;

sub one {
    is $inc, 1, "Incrementer is 1";
    is $inc, $_[0], "\$inc was passed to ratchet";
}

sub two {
    is $inc, 2, "Incrementer is 2";
    is $inc, $_[0], "\$inc was passed to ratchet";
    is $_[1], 'test', "Other args were passed";
}

sub three_four_five {
    state $should_be = 3;

    is $inc, $should_be, "three-four-five called with $should_be";
    $should_be++;

    is scalar @_, 0, "Nothing passed";
}

sub indefinite {
    state $should_be = 6;

    is $inc, $should_be, "three-four-five called with $should_be";
    $should_be++;
}

sub fail_if_called {
    fail "This should never get called!";
}
