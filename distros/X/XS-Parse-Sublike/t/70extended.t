#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   $] >= 5.026000 or plan skip_all => "No parse_subsignature()";
}

use feature 'signatures';
no warnings 'experimental';

use Sublike::Extended;

# basic sub
{
   extended sub t1 { return "named" }
   my $t2 = extended sub { return "anon" };

   is( t1(), "named",
      'extended sub can make basic named' );
   is( $t2->(), "anon",
      'extended sub can make basic anon' );
}

# sub with named params
{
   extended sub t3 (:$x, :$y) { return "x=$x y=$y"; }
   my $t4 = extended sub ( :$i, :$j ) { return "i=$i j=$j"; };

   is( t3( x => 10, y => 20 ), "x=10 y=20",
      'extended sub can make named param subs' );
   is( $t4->( j => 40, i => 30 ), "i=30 j=40",
      'extended sub can make named param anon subs' );
}

use lib "t";
use testcase "t::func";

BEGIN { $^H{"t::func/Attribute"}++ }

our @ATTRIBUTE_APPLIED;

{
   extended sub t5 ($x :Attribute, $y :Attribute(Value)) { }

   my @t5_attributes;
   BEGIN { @t5_attributes = @ATTRIBUTE_APPLIED; @ATTRIBUTE_APPLIED = (); }

   # No need to call it just to see these

   is( \@t5_attributes,
      [ '$x' => undef, '$y' => "Value" ],
      ':Attribute applied to subroutine parameters' );
}

{
   use Sublike::Extended 'sub';

   sub t6 ( $z :Attribute, :$alpha :Attribute(Value) ) { }

   my @t6_attributes;
   BEGIN { @t6_attributes = @ATTRIBUTE_APPLIED; @ATTRIBUTE_APPLIED = (); }

   is( \@t6_attributes,
      [ '$z' => undef, ':$alpha' => "Value" ],
      ':Attribute applied to subroutine parameters of `sub` directly' );
}

done_testing;
