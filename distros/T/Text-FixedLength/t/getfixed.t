#!/usr/local/bin/perl5.004
# ----------------------------------------------------------------------------
# Name: test: getfixed
# Auth: Dion Almaer (dion)
# Desc: Test the fixed areas
# Date Created: Sun Nov 15 18:21:04 1998
# Version: 0.11
# $Modified: Sun Nov 15 18:21:34 1998 by dion $
# ----------------------------------------------------------------------------
use strict;
use lib '../blib/lib';
use Text::FixedLength;

BEGIN { print "1..2\n"; }

my @fL = qw(4L 4L 4L 4L);
my @fR = qw(4R 4R 4R 4R);
my $str= join "\t", qw(1 2 3 4);
my $out1= '1   2   3   4   ';
my $out2= '   1   2   3   4';

my @a1 = delim2fixed([ $str ],"\t", \@fL);
my $r1 = ($a1[0] eq $out1) ? "ok 1\n" : "not ok 1\n";
print $r1;

my @a2 = delim2fixed([ $str ],"\t", \@fR);
my $r2 = ($a2[0] eq $out2) ? "ok 2\n" : "not ok 2\n";
print $r2;

# ----------------------------------------------------------------------------
#      End of Program
# ----------------------------------------------------------------------------
