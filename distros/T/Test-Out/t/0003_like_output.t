#!/usr/bin/env perl

use strict;
use warnings;

use Test::Out;

my $out = Test::Out->new(output => \*STDOUT, tests => 1);

MAIN: {
    my ($t0);
    $t0 = test_stdout();
    $out->restore;
    exit(0);
}

sub test_stdout {
    print "Random number: @{[int rand 100]}\n";
    my $rv = $out->like_output(qr/number: \d+/, "Contains random number");
    return $rv;
}

