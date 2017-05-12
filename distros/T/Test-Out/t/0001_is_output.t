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
    print "this is a test\n";
    my $rv = $out->is_output("this is a test\n", "is_output succeeds");
    return $rv;
}

