#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Test::More qw(no_plan);

my $file="t/warnings_exist1.pl";
my $output=`$^X -Mblib $file 2>&1`;
$output=~s/^#.*$//gm;
$output=~s/\n{2,}/\n/gs;
my @lines=split /[\n\r]+/,$output;
shift @lines if $lines[0]=~/^Using /; #extra line in perl 5.6.2
shift @lines if $lines[0]=~/^TAP version /; #extra line in new TAP

#print $output;
my @expected=(
"warn_2 at $file line 12.",
'ok 1',
"warn_1 at $file line 17.",
'ok 2',
'ok 3',
"warn_2 at $file line 26.",
'not ok 4',
"warn_2 at $file line 32.",
'ok 5',
"warn_2 at $file line 36.",
'not ok 6',
qr/^Use of uninitialized value (?:\$a\s+)?in addition \(\+\) at \Q$file\E line 41\.$/,
'ok 7',
'1..7'
);
foreach my $i (0..$#expected) {
  if ($expected[$i]=~/^\(\?\^?\w*-?\w*:/) {
    like($lines[$i],$expected[$i]);
  } else {
    is($lines[$i],$expected[$i]);
  }
}
