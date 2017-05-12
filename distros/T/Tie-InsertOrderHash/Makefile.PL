#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence the
# contents of the Makefile that is written.

my $source_file = 'InsertOrderHash.pm';

WriteMakefile
  (NAME	=> 'Tie::InsertOrderHash',
   VERSION_FROM	=> $source_file,
   ABSTRACT_FROM => $source_file,
   AUTHOR => 'B. K. Oxley (binkley) <binkley@bigfoot.com>');

1;
