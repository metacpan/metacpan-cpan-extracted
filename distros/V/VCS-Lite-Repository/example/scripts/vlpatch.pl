#!/usr/local/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $output;

GetOptions(
	'output=s' => \$output,
	);

if (!@ARGV) {
	print <<END;

Usage:  vlpatch.pl [--output outfile] original patch
	vlpatch [--output outfile] original	# take patch from stdin

if --output is not specified, the patched file is put in place of
the original, and the original is renamed to *.orig

END
	exit;
}

my $orig = shift @ARGV;
my ($pat,$patsrc) = @ARGV ? ($ARGV[0],$ARGV[0]) : (\*STDIN,'-');
my $el1 = VCS::Lite->new($orig);
my $dt1 = VCS::Lite::Delta->new($patsrc,undef,$orig,$pat);

my $chg = $el1->patch($dt1) or die "Patch failed";

if (!$output) {
	rename $orig "$orig.orig";
	$output = $orig;
}

open PAT,">$output" or die "Failed to write output, $!";
print PAT $chg->text;
close PAT;

