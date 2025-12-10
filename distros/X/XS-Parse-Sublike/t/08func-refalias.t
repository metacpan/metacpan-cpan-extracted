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

# refalias parameters can have defaults
{
   rfunc add_them_all(\@arr = [1, 2]) {
      my $n = 0;
      $n += $_ for @arr;
      return $n;
   }

   is( add_them_all(),           3, 'refalias with default applies when absent' );
   is( add_them_all( [ 4, 5 ] ), 9, 'refalias param default can be overridden' );

   rfunc default_explodes(\@arr = die "This should not be invoked") { }

   ok( lives { default_explodes( [] ) },
      'Defaulting expression of refalias parameter is not invoked with passed value' );
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

# refalias on named parameters
{
   rfunc refnamed_scalar( :\$scl ) { return 0 + !!defined $scl; }
   rfunc refnamed_array ( :\@arr ) { return scalar @arr; }
   rfunc refnamed_hash  ( :\%hsh ) { return scalar keys %hsh; }

   is( refnamed_scalar( scl => \1 ), 1,
      'Refalias named scalar parameter' );
   is( refnamed_array( arr => ['x', 'y', 'z'] ), 3,
      'Refalias named array parameter' );
   is( refnamed_hash( hsh => { x => 1, y => 2 } ), 2,
      'Refalias named hash parameter' );

   like( dies { refnamed_array() },
      qr/^Missing argument 'arr' for subroutine main::refnamed_array at /,
      'complaint from missing named param' );
}

# refalias named can have defaults
{
   rfunc refnamed_maybe_array( :\@arr = [2] ) { return $arr[0]; }

   is( refnamed_maybe_array( ), 2,
      'Refalias named array parameter default applies' );
   is( refnamed_maybe_array( arr => [5] ), 5,
      'Refalias named array parameter with value overrides default' );
}

done_testing;
