#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
 eval 'use Tie::Hash; scalar keys %Tie::StdHash::'
                or plan skip_all => 'Tie::StdHash required to test tied hashes';
 defined and diag "Using Tie::StdHash $_" for $Tie::Hash::VERSION;
 plan tests => 1;
}

{
 tie my %x, 'Tie::StdHash';
 tie my %y, 'Tie::StdHash';

 $x{key} = 'hlagh';
 $y{x}   = \%x;

 my $res = do {
  no autovivification;
  $y{x}{key};
 };
 is $res, 'hlagh', 'nested tied hashes';
}
