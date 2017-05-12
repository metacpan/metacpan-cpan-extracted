#!/usr/bin/perl

use strict;

use Tie::Scalar::RestrictUpdates;

my $foo;
tie $foo,"Tie::Scalar::RestrictUpdates",5;
for(1..10) { $foo = $_; print $foo; }
