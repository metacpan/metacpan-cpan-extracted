#!perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::NoTty;

require './t/force-a-tty.pl';

{
    my $pid = $$;
    # "Pick a card"
    my @array = keys %ENV;
    my $index = rand @array;
    my $pick = $array[$index];

    # You need this sort of construction to run tests within your block
    # Or you just use Test2::IPC and remove 4 lines of fragile boilerplate
    my $Test = Test::Builder->new;
    my $curr_test = $Test->current_test;
    my $count = without_tty(sub {
        my ($a) = @_;
        isnt($$, $pid, "We're actually running in a different process");
        # We can pass *in* arguments, including structures and objects
        # And we inherit our lexical state, just as expected
        is($a->[$index], $pick, "Random array of element found");

        # Two tests ran in the child that our parent doesn't know about:
        return 2;
    }, \@array);
    $Test->current_test($curr_test + $count);
}

done_testing;
