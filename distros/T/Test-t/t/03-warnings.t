#!/usr/bin/env perl
use Test::t;

warning_like { eval q/my $xyzzy; "$xyzzy"; $xyzzy;/ } [qw/ void uninitialized /];

1;
