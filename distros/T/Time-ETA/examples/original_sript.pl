#!/usr/bin/perl

use strict;
use warnings;

sub do_work {
    print "Working...\n";
    sleep 1;
};

my $count = 6;

foreach (1..$count) {
    do_work();
}

print "Finished!\n";
