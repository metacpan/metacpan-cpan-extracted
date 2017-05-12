#!/usr/bin/perl -w
use strict;
use warnings;

my $lastrow = "";
while (my $line = <>) {
    $line =~ /(.*?)\n/;
    $line = $1;
    if ($line ne $lastrow) {
        print $line, "\n";
        $lastrow = $line;
    }
}

