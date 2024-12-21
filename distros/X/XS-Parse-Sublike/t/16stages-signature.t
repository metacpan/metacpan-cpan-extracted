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
use testcase "t::stages";

BEGIN { $^H{"t::stages/permit"} = 1; }

{
   BEGIN { $^H{'t::stages/signature-capture'} = 1; }
   my $captured;
   stages withsig ( $x, $y ) { BEGIN { $captured = $t::stages::captured; undef $t::stages::captured; } }

   is( $captured, "(SIG[n=2])",
      'captured signature start + finish before body' );
}

{
   BEGIN { $^H{'t::stages/signature-capture'} = 1; }
   my $captured;
   stages withemptysig () { BEGIN { $captured = $t::stages::captured; undef $t::stages::captured; } }

   is( $captured, "(SIG[n=0])",
      'captured signature start + finish from empty signature' );
}

{
   BEGIN { $^H{'t::stages/signature-add-$first'} = 1; }

   stages withfirst ( $x, $y ) { return $first; }

   is( withfirst( 1 .. 3 ), 1,
      'signature start can add $first param' );
}

{
   BEGIN { $^H{'t::stages/signature-add-@rest'} = 1; }

   stages withrest ( $x, $y ) { return [ @rest ]; }

   is( withrest( 1 .. 5 ), [ 3 .. 5 ],
      'signature finish can add @rest param' );
}

done_testing;
