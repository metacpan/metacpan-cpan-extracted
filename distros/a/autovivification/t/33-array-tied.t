#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
 eval 'use Tie::Array; scalar keys %Tie::StdArray::'
               or plan skip_all => 'Tie::StdArray required to test tied arrays';
 defined and diag "Using Tie::StdArray $_" for $Tie::Array::VERSION;
 plan tests => 1;
}

{
 tie my @a, 'Tie::StdArray';
 tie my @b, 'Tie::StdArray';

 $a[1] = 'hlagh';
 $b[0] = \@a;

 my $res = do {
  no autovivification;
  $b[0][1];
 };
 is $res, 'hlagh', 'nested tied arrays';
}
