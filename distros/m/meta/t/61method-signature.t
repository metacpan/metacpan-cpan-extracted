#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.38 or
      plan skip_all => "Not supported on Perl $^V";
}

use meta;
no warnings qw( meta::experimental );

use feature 'class';
no warnings qw( experimental::class );

class TestClass {
   method testmethod ( $x, $y, $z = undef ) { ... }
}

my $metaclass = meta::package->get( "TestClass" );

{
   my $metamethod = $metaclass->get_symbol( '&testmethod' );

   my $metasig = $metamethod->signature;
   ok( $metasig, '$metamethod->signature yields something' );

   # Implicit $self should count as an additional mandatory argument
   is( $metasig->mandatory_params, 3, 'signature has 3 mandatory params' );
   is( $metasig->optional_params,  1, 'signature has 1 optional param' );
   is( $metasig->slurpy, undef,       'signature has no slurpy param' );

   is( $metasig->min_args, 3, 'signature requires at least 3 argument values' );
   is( $metasig->max_args, 4, 'signature supports at most 4 argument values' );
}

done_testing;
