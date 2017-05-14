#!/usr/bin/perl -w

use strict;
use warnings;

my $file = '/manish-scripts/test';
my %seen = ();
{
   local @ARGV = ($file);
   local $^I = '.bac';
   while(<>){
      $seen{$_}++;
      next if $seen{$_} > 1;
      print;
   }
}
print "finished processing file.";
