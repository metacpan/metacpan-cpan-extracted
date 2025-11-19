#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000147;  # is_oneref
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/rfunc"}++ }

{
   rfunc totals(\@array, \%hash) {
      return scalar @array + scalar keys %hash;
   }

   is( totals( [10, 11], {a => "A"} ), 3,
      'func with refalias invoked');

   like( dies { totals( {}, {} ) },
      qr/^Expected argument 1 to main::totals to be a reference to ARRAY at /,
      'Exception thrown by wrong reference type' );
   like( dies { totals( [], [] ) },
      qr/^Expected argument 2 to main::totals to be a reference to HASH at /,
      'Exception thrown by wrong reference type' );
}

# refaliased variables can be edited in place
{
   rfunc inc_all(\@arr) {
      $_++ for @arr;
   }

   my @array = ( 1, 2, 3 );
   inc_all \@array;
   is( \@array, [ 2, 3, 4 ],
      'refalias func can mutate caller-passed container' );

   my $arr = [];
   inc_all $arr;
   is_oneref( $arr, '$arr has one reference after refaliasing call' );
}

done_testing;
