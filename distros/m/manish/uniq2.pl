#!/usr/bin/perl -w
use warnings;
use strict;
my %seen; 
my $n; 
foreach (<>) { 
  $n++ && print 
    unless $seen{$_}++ 
  } 
print "$n \n";


