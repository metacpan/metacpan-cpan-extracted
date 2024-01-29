#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

our $SCALAR = "the scalar";

{
   my $metavar = meta::package->get( "main" )->get_symbol( '$SCALAR' );

   ok( !$metavar->is_glob,       '$metavar->is_glob false' );
   ok(  $metavar->is_scalar,     '$metavar->is_scalar' );
   ok( !$metavar->is_array,      '$metavar->is_array false' );
   ok( !$metavar->is_hash,       '$metavar->is_hash false' );
   ok( !$metavar->is_subroutine, '$metavar->is_subroutine false' );

   is( $metavar->value, "the scalar",
      '$metavar->value of $SCALAR' );
}

our @ARRAY = qw( ab cd ef );

{
   my $metavar = meta::package->get( "main" )->get_symbol( '@ARRAY' );

   ok( $metavar->is_array, '$metavar->is_array' );

   is( scalar $metavar->value, 3,
      '$metavar->value of @ARRAY in scalar context' );
   is( [ $metavar->value ], [qw( ab cd ef )],
      '$metavar->value of @ARRAY in list context' );
}

our %HASH = ( one => 1, two => 2 );

{
   my $metavar = meta::package->get( "main" )->get_symbol( '%HASH' );

   ok( $metavar->is_hash, '$metavar->is_hash' );

   is( scalar $metavar->value, 2,
      '$metavar->value of %HASH in scalar context' );
   is( { $metavar->value }, { one => 1, two => 2 },
      '$metavar->value of %HASH in list context' );
}

done_testing;
