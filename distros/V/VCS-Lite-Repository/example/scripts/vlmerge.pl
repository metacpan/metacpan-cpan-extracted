#!/usr/local/bin/perl

use strict;
use warnings;

use VCS::Lite;
use Getopt::Long;

my $output;

GetOptions(
	'output=s' => \$output
	);

if (@ARGV != 3) {
	print <<END;

Usage:	$0 [--output outfile] original changed1 changed2

If --output is not specified, the results are put in place
of the original, and the original is renamed to *.orig

END
	exit;
}

my ($orig,$chg1,$chg2) = @ARGV;

my $el1 = VCS::Lite->new($orig);
my $el2 = VCS::Lite->new($chg1);
my $el3 = VCS::Lite->new($chg2);

my $el4 = $el1->merge($el2,$el3) or die "Merge failed";

if (!$output) {
	rename $orig, "$orig.orig";
	$output = $orig;
}

open MERGE,">$output";
print MERGE $el4->text;
close MERGE;

