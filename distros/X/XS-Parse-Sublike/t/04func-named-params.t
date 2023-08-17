#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use lib "t";
use testcase "t::func";

# a signature with experimental named parameter support
{
   my %was_rest;
   nfunc withx(:$x, %rest) { %was_rest = %rest; return $x }

   is( withx( x => 123 ), 123, 'named param extracts value' );
   is( \%was_rest, {},  'named param not visible in %rest' );

   withx( x => 1, y => 2 );
   is( \%was_rest, { y => 2 }, 'other params still visible in %rest' );

   like( dies { withx() },
      qr/^Missing argument 'x' for subroutine main::withx /,
      'complaint from missing named param' );
}

# named params can still have defaults
{
   nfunc withy(:$y = "Y", %rest) { return $y }

   is( withy( y => 456 ), 456, 'named param with default' );
   is( withy(),           "Y", 'named param applies default' );
}

# named params still work without a slurpy
{
   nfunc withz(:$z) { return $z }

   is( withz( z => 789 ), 789, 'named param without slurpy' );

   like( dies { withz( z => 1, w => 1 ); 1 },
      qr/^Unrecognised argument 'w' for subroutine main::withz /,
      'complaint from unknown param' );
}

done_testing;
