#!/usr/bin/perl

use Tie::Array::RestrictUpdates;

my @foo = ();
tie @foo,"Tie::Array::RestrictUpdates",1;
# Default limit is 1.
# Every element from the array can only be changed once
@foo = qw(A B C D E);
for(0..4) { $foo[$_] = lc $foo[$_]; }
print join("-",@foo);
# This will print A-B-C-D-E and a bunch of warnings
