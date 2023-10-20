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

BEGIN { $^H{"t::func/nfunc"}++ }

# a signature with experimental named parameter support
{
   my %was_rest;
   nfunc withx(:$x, %rest) { %was_rest = %rest; return $x }

   is( withx( x => 123 ), 123, 'named param extracts value' );
   is( \%was_rest, {},  'named param not visible in %rest' );

   withx( x => 1, y => 2 );
   is( \%was_rest, { y => 2 }, 'other params still visible in %rest' );

   my $LINE = __LINE__+1;
   like( dies { withx() },
      qr/^Missing argument 'x' for subroutine main::withx at \S+ line $LINE\./,
      'complaint from missing named param' );

   nfunc with2x(:$x1, :$x2) { return "x1=$x1 x2=$x2"; }
   is( with2x( x1 => 10, x2 => 20 ), "x1=10 x2=20",
      'supports multiple named params' );
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

   my $LINE = __LINE__+1;
   like( dies { withz( z => 1, w => 1 ); 1 },
      qr/^Unrecognised argument 'w' for subroutine main::withz at \S+ line $LINE\./,
      'complaint from unknown param' );
}

# mixed positional+named
{
   nfunc withboth($x, :$y = "def") { return "x=$x y=$y"; }

   is( withboth(1, y => 2), "x=1 y=2",
      'supports mixed positional + named' );
   is( withboth(1), "x=1 y=def",
      'mixed still applies defaults' );
}

# diagnostics on duplicates
{
   sub warnings_from ( $code ) {
      my $warnings = "";
      local $SIG{__WARN__} = sub { $warnings .= $_[0] };
      eval( "$code; 1" ) or die $@;
      return $warnings;
   }

   like( warnings_from( 'nfunc diag1($x, :$x) { }' ),
      qr/^"my" variable \$x masks earlier declaration in same scope at /,
      'warning from duplicated parameter name' );
}

done_testing;
