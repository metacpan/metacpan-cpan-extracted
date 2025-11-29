#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

my $metapkg = meta::package->get( "main" );

# scalar
{
   our $SCALAR_VAR;

   $metapkg->remove_symbol( '$SCALAR_VAR' );

   ok( !$metapkg->try_get_symbol( '$SCALAR_VAR' ),
      '$metapkg no longer has scalar symbol after remove' );
   ok( !$metapkg->try_get_glob( 'SCALAR_VAR' ),
      '$metapkg no longer has old glob after remove' );

   like( dies { $metapkg->remove_symbol( '$SCALAR_VAR' ) },
      qr/^Cannot remove non-existing symbol "\$SCALAR_VAR" from package /,
      '->remove_symbol on same name throws exception' );
}

# array
{
   our @ARRAY_VAR;

   $metapkg->remove_symbol( '@ARRAY_VAR' );

   ok( !$metapkg->try_get_symbol( '@ARRAY_VAR' ),
      '$metapkg no longer has array symbol after remove' );
   ok( !$metapkg->try_get_glob( 'ARRAY_VAR' ),
      '$metapkg no longer has old glob after remove' );
}

# hash
{
   our %HASH_VAR;

   $metapkg->remove_symbol( '%HASH_VAR' );

   ok( !$metapkg->try_get_symbol( '%HASH_VAR' ),
      '$metapkg no longer has hash symbol after remove' );
   ok( !$metapkg->try_get_glob( 'HASH_VAR' ),
      '$metapkg no longer has old glob after remove' );
}

# hash
{
   sub FUNCTION { }

   $metapkg->remove_symbol( '&FUNCTION' );

   ok( !$metapkg->try_get_symbol( '&FUNCTION' ),
      '$metapkg no longer has code symbol after remove' );
   ok( !$metapkg->try_get_glob( 'FUNCTION' ),
      '$metapkg no longer has old glob after remove' );
}

# can delete one slot without losing them all
{
   our $SHARED;
   our @SHARED;
   our %SHARED;

   $metapkg->remove_symbol( '@SHARED' );

   ok( !$metapkg->try_get_symbol( '@SHARED' ),
      '$metapkg no longer has @SHARED after remove' );
   ok( $metapkg->try_get_symbol( '$SHARED' ),
      '$metapkg still has $SHARED after remove array' );
   ok( $metapkg->try_get_symbol( '%SHARED' ),
      '$metapkg still has %SHARED after remove array' );

   like( dies { $metapkg->remove_symbol( '@SHARED' ) },
      qr/^Cannot remove non-existing symbol "\@SHARED" from package /,
      '->remove_symbol on same name throws exception' );
}

done_testing;
