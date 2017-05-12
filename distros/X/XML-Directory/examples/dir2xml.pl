#!/usr/bin/perl

use XML::Directory(qw(get_dir));
use strict;

(@ARGV == 1 ) || die ("Usage: dir2xml.pl path\n\n");

my $dir = shift;

my @xml = get_dir($dir);

foreach (@xml) {
    print "$_\n";
}

exit 0;

