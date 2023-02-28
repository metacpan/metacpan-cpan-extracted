#!perl

use strict;
use warnings;

# This dance in the BEGIN block is only because I can't test the code with
# "classic" Test::Builder if my META.json has a dependency on Test2.
# If I did that, then my @INC tree is always "upgraded" to the Test2 version of
# Test::More, and the test1.t version of this *never* tests the "classic"
# version, even starting from a fresh install of v5.24.x or earlier

BEGIN {
    unless(eval {
        require Test2::Bundle::More;
        Test2::Bundle::More->import;
        1;
    }) {
        my $error = $@;
        if ($error =~ m!\ACan't locate Test2/Bundle/More\.pm in \@INC!) {
            print "1..0 # Skip Test2 not installed\n";
            exit 0;
        }
        $error =~ s/^/# /gm;
        print <<"EOT";
1..1
not ok 1 - Test2::Bundle::More failed to load
$error
EOT
        exit 1;
    }
}

use Test2::IPC;
use Test::NoTty;

require './t/force-a-tty.pl';

# Compare this with the "classic" implementation (Test::More) where we have to
# dance around with Test::Builder objects and remembering to return the test
# count.
# If you're running 5.26.0 or later *or* have non-trivial CPAN modules installed
# you've already got Test2 in @INC, so just use 2.

{
    my $pid = $$;
    # "Pick a card"
    my @array = keys %ENV;
    my $index = rand @array;
    my $pick = $array[$index];

    without_tty(sub {
        my ($a) = @_;
        isnt($$, $pid, "We're actually running in a different process");
        # We can pass *in* arguments, including structures and objects
        # And we inherit our lexical state, just as expected
        is($a->[$index], $pick, "Random array of element found");

    }, \@array);
}

done_testing;
