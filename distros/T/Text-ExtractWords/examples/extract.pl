#!/usr/bin/perl

use strict;
use Text::ExtractWords qw(words_count);

my $file = $ARGV[0] or die("no file");

my %hash = ();
my %config = (
	minlenword => 1,
	maxlenword => 32,
	locale     => "pt_PT.ISO_8859-1"
);
open(FILE, "<$file") or die("$!");
while(<FILE>) {
	words_count(\%hash, $_, \%config);
}
close(FILE);

while(my ($k, $v) = each(%hash)) {
	print "$k => $v\n";
}

exit();
