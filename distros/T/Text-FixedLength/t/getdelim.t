#!/usr/local/bin/perl5.004
# ----------------------------------------------------------------------------
# Name: test: getdelim
# Auth: Dion Almaer (dion)
# Desc: Test the delim areas
# Date Created: Sun Nov 15 18:21:04 1998
# Version: 0.11
# $Modified: Sun Nov 15 18:21:34 1998 by dion $
# ----------------------------------------------------------------------------
use strict;
use lib '../blib/lib';
use Text::FixedLength;

BEGIN { print "1..1\n"; }

my $out = '22:333:4444:1';

my @a1 = fixed2delim([ '2233344441' ], [qw(2 3 4 1)], ':');
my $r1 = ($a1[0] eq $out) ? "ok 1\n" : "not ok 1\n";
print $r1;
# ----------------------------------------------------------------------------
#      End of Program
# ----------------------------------------------------------------------------
