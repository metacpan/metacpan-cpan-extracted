#!/usr/bin/env perl

# This program determines exactly which modules are used by
# the module "File::Spec".

# Important: Do not use any other modules or pragmas in this program!

use File::Spec;

foreach (keys %INC) {
  s/\.[^.]+$//; # strip extension
  s/\//::/g;
  print "$_\n";
}

