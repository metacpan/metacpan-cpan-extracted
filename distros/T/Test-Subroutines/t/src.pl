#!/usr/bin/perl

use Getopt::Long;
my $i = 2;

sub doit {
    my $j = $i;
    $j++;
    print $j, " XXX\n";
    system ('ls');
    exit 5;
}

