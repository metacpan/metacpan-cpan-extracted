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

BEGIN { $^H{"t::func/afunc"}++ }
BEGIN { $^H{"t::func/Attribute"}++ }

our @ATTRIBUTE_APPLIED;
our @ATTRIBUTE_SAW_OPTREES;
our $ATTRIBUTE_INVOKED;

sub NZ { !Test2::Tools::Compare::number(0); }

{
   afunc withattr( $x :Attribute, $y :Attribute(Value) = 123 ) { }

   is( \@ATTRIBUTE_APPLIED,
      [ '$x' => undef, '$y' => "Value" ],
      ':Attribute applied to subroutine parameters' );

   is( \@ATTRIBUTE_SAW_OPTREES,
      [
         { op => NZ(), varop => NZ(), defop => 0 },
         { op => NZ(), varop => NZ(), defop => NZ() },
      ],
      ':Attribute saw some optrees' );

   withattr( "X", "Y" );

   is( $ATTRIBUTE_INVOKED, 2,
      ':Attribute modified optree got invoked' );
}

if( $^V ge v5.26 ) {
   undef @ATTRIBUTE_APPLIED;
   undef @ATTRIBUTE_SAW_OPTREES;
   undef $ATTRIBUTE_INVOKED;

   BEGIN { $^H{"t::func/nafunc"}++ }
   BEGIN { $^H{"t::func/Attribute"}++ }

   defined eval <<'EOF'
nafunc withattrnamed( :$alpha :Attribute, :$beta :Attribute(NamedValue) = 456 ) { }
1;
EOF
      or die "Cannot compile - $@";

   is( \@ATTRIBUTE_APPLIED,
      [ ':$alpha' => undef, ':$beta' => "NamedValue" ],
      ':Attribute applied to named subroutine parameters' );

   # Named params don't get a varop
   # They don't get an op *at all* if there's no default
   is( \@ATTRIBUTE_SAW_OPTREES,
      [
         { op => 0,    varop => 0, defop => 0 },
         { op => NZ(), varop => 0, defop => NZ() },
      ],
      ':Attribute saw some optrees' );

   withattrnamed( alpha => "A", beta => "B" );

   is( $ATTRIBUTE_INVOKED, 2,
      ':Attribute modified optree got invoked for named' );
}

# RT168812
# In this file purely to ensure we use our version of parse_subsignature()
{
   is(
      eval( 'afunc f01( $ = undef ) { }; 1' ) ? undef : $@,
      undef,
      'Function with anonymous parameter default expression as undef is permitted' );

   like(
      eval( 'afunc f02( $ = 123 ) { }' ) ? undef : $@,
      qr/^Unnamed positional parameters cannot have defaulting expressions /,
      'Function with anonymous parameter defaulting expression fails to parse' );

   is(
      eval( 'afunc f03( $x = ) { }; 1' ) ? undef : $@,
      undef,
      'Function with missing parameter default expression implies undef' );

   is(
      eval( 'afunc f04( $ = ) { }; 1' ) ? undef : $@,
      undef,
      'Function with missing unnamed parameter default expression implies undef' );

   is(
      eval( 'afunc f05( $= ) { }; 1' ) ? undef : $@,
      undef,
      'Function with missing unnamed parameter default expression implies undef' );
}

done_testing;
