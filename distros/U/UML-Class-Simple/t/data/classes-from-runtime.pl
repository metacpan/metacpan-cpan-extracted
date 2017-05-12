#!/usr/bin/env perl

# This program determines exactly which modules are used by
# the module "UMLClassTest," which we created for testing purposes.

# Important: Do not use any other modules or pragmas in this program!

use UMLClassTest;

foreach (keys %INC) {
  s/\.[^.]+$//; # strip extension
  s/\//::/g;
  print "$_\n";
}

