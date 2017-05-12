#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Time::Duration::Patch::Millisecond;
use Time::Duration;

my @basic_tests = (
    [ duration(   1.10), '1 second and 100 milliseconds' ],
    [ ago     (   0.03), '30 milliseconds ago' ],
);

# --------------------------------------------------------------------
# Some tests of concise() ...

my @concise_tests = (
    [ concise duration(   0.10), '100ms' ],
    [ concise ago     (   1.02), '1s20ms ago' ],
);

# --------------------------------------------------------------------
# execute the test

for my $case (@basic_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

for my $case (@concise_tests) {
    is($case->[0], $case->[1], $case->[1]);
}

done_testing;
