#!/usr/bin/perl -w
#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision: 1.3 $
# Author          : Ulrich Pfeifer
# Created On      : Wed Jun 18 19:44:37 2003
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Oct 21 10:29:42 2008
# Language        : CPerl
# 
# (C) Copyright 2003, UUNET Deutschland GmbH, Germany
# 
use strict;
use Test;
BEGIN {
    if (!eval {
	require File::Temp;
	require File::Spec;
	require Cwd;
	1;
    }) {
	print "1..0 # SKIP: File::Temp and/or File::Spec not available, skipping tests\n";
	exit(0);
    }
    File::Temp->import(qw(tempdir));
}
BEGIN { plan tests => 2, todo => [] }

sub run {
  my ($cmd, $test) = @_;

  local $/;
  open(SUB, "$^X $cmd < " . File::Spec->devnull . " 2>&1 |") or die $!;
  my $result = <SUB>;
  close SUB or return;

  return &$test($result);
}

my $tmp = tempdir(CLEANUP => 1);
my $cwd = Cwd::getcwd();

ok(
   run(
       "-Mblib ./perlindex -idir $tmp --index $cwd/README $cwd/MANIFEST $cwd/perlindex.PL",
       sub { print "[[$_[0]]]\n"; $_[0] =~ /MANIFEST/ }
      )
  );
ok(
   run(
       "-Mblib ./perlindex -idir $tmp --nomenu index",
       sub { print "[[$_[0]]]\n"; $_[0] =~ /perlindex.PL/ }
      )
  );
