#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 18;
use lib "lib";

BEGIN { 
    use_ok 'WWW::Selenium::Utils::Actions', qw(%selenium_actions);
}

my %actions = (
    'Open' => 1,
    'GoBack' => 0,
    'ModalDialogTest' => 1,
    'Store' => 2,
    'ChooseCancelOnNextConfirmation' => 0,
    'FireEvent' => 2,
    'Close' => 0,
    'AnswerOnNextPrompt' => 1,
    'Select' => 2,
    'StoreText' => 2,
    'StoreAttribute' => 2,
    'Click' => 1,
    'SelectWindow' => 1,
    'StoreValue' => 2,
    'Type' => 2,
    'Context' => 1
);
# convert to all lower case
$actions{lc($_)} = delete $actions{$_} for keys %actions;

is keys %selenium_actions, keys %actions;
for my $k (keys %actions) {
    is $selenium_actions{$k}, $actions{$k};
}

1;



