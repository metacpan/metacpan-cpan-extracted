#!/usr/bin/perl

use Tie::Array::RestrictUpdates;

my @foo = ();
tie @foo,"Tie::Array::RestrictUpdates",[1,2,3,4];
# This forces the limits of the first 3 indexes
# This also forces any extra elements from the array to have a 0 limit
# and therefor be unchangable/unsettable
@foo = qw(A B C D E);
for(0..3) { $foo[$_] = lc $foo[$_]; }
for(0..3) { $foo[$_] = uc $foo[$_]; }
for(0..3) { $foo[$_] = lc $foo[$_]; }
for(0..3) { $foo[$_] = uc $foo[$_]; }
print join("-",@foo);
# This will print A-b-C-d and a bunch of warnings
