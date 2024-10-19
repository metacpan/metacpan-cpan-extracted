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

   like( dies { with2x() },
      # Order here is not reliable
      qr/^Missing arguments 'x[12]', 'x[21]' for subroutine main::with2x at /,
      'complaint from missing two named params includes both' );
}

# named params can still have defaults
{
   nfunc withy(:$y = "Y", %rest) { return $y }

   is( withy( y => 456 ), 456, 'named param with default' );
   is( withy(),           "Y", 'named param applies default' );
}

# named param defaulting expressions can still see earlier named params
{
   my $ret_y; my $got_x;
   sub y_from_x ($x) { $got_x = $x; return $ret_y; }

   nfunc withdefaults(:$x, :$y = y_from_x($x)) { return "$x-$y" }

   $ret_y = "Y_VALUE";
   is( withdefaults( x => "X_VALUE" ), "X_VALUE-Y_VALUE",
      'named param defaults can see earlier default params' );
   is( $got_x, "X_VALUE", 'param default expression was invoked' );
}

# named params can use //= and ||=
{
   nfunc withdefined(:$x //= "default") { return $x }

   is( withdefined( x => "value" ), "value",   'named param with defined-or' );
   is( withdefined( x => undef ),   "default", 'named param with defined-or defaulting' );

   nfunc withtrue(:$x ||= "default") { return $x }

   is( withtrue( x => "value" ), "value",   'named param with true-or' );
   is( withtrue( x => "" ),      "default", 'named param with true-or defaulting' );
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

   nfunc withlots($p1, $p2, $p3, :$n1, :$n2, :$n3) {
      return "($p1, $p2, $p3) + (1=$n1, 2=$n2, 3=$n3)";
   }

   is( withlots("a", "b", "c", n1 => "d", n3 => "f", n2 => "e"),
      "(a, b, c) + (1=d, 2=e, 3=f)",
      'supports multiple positional + named');
}

# named params can support a slurpy array
{
   nfunc withslurpyarray(:$alpha = undef, :$beta = undef, @rest) {
      return @rest;
   }

   is( [ withslurpyarray( x => 123, alpha => "no", beta => "no", y => 456, x => 789 ) ],
      [ x => 123, y => 456, x => 789 ],
      'supports slurpy array that preserves duplicates/order' );

   is( [ withslurpyarray( 'single' ) ],
      [ 'single' ],
      'slurpy array does not gain phantom undef' );
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

# RT155654
{
   nfunc unnamedslurpyarray($x, :$y, @) { return "x=$x y=$y"; }

   nfunc unnamedslurpyhash ($x, :$y, %) { return "x=$x y=$y"; }

   pass( 'code with unnamed slurpies compiles OK' );

   is( unnamedslurpyarray( "X", y => "Y", more => "here" ), "x=X y=Y",
      'result of invoking function with unnamed slurpy array' );

   is( unnamedslurpyhash ( "X", y => "Y", more => "here" ), "x=X y=Y",
      'result of invoking function with unnamed slurpy hash' );
}

done_testing;
