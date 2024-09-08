#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

our $VAR;
our @VAR;

# via glob
{
   my $metapkg = meta::package->get( "main" );
   my $metaglob = $metapkg->get_glob( "VAR" );
   my $metasym = $metaglob->get_scalar;
   ok( $metasym, '$metaglob->get_scalar' );

   is( $metasym->reference, \$VAR,
      '$metasym->reference' );

   is( $metaglob->get_array->reference, \@VAR,
      '$metaglob->get_array->reference' );
}

# missing
{
   my $metapkg = meta::package->get( "main" );
   my $metaglob = $metapkg->get_glob( "VAR" );
   ok( !defined $metaglob->try_get_hash,
      'try_get_hash yields undef on missing HV' );

   like( dies { $metaglob->get_hash },
      qr/^Glob does not have a hash slot /,
      'get_hash throws on missing HV' );
}

# direct shortcut
{
   my $metapkg = meta::package->get( "main" );

   is( $metapkg->get_symbol( '$VAR' )->reference, \$VAR,
      '$metapkg->get_symbol for scalar' );

   is( $metapkg->try_get_symbol( '$VAR' )->reference, \$VAR,
      '$metapkg->try_get_symbol for scalar' );

   is( $metapkg->get_or_add_symbol( '$VAR' )->reference, \$VAR,
      '$metapkg->get_or_add_symbol for scalar' );

   is( $metapkg->get_symbol( '@VAR' )->reference, \@VAR,
      '$metapkg->get_symbol for array' );

   ok( !defined $metapkg->try_get_symbol( '%VAR' ),
      'try_get_symbol yields undef on missing HV' );

   like( dies { $metapkg->get_symbol( '%VAR' ) },
      qr/^Package has no symbol named "%VAR" /,
      'get_symbol throws on missing HV' );

   like( dies { $metapkg->get_symbol( '%missing-name' ) },
      qr/^Package has no symbol named "%missing-name" /,
      'get_symbol throws on missing GV' );
}

sub func {}

{
   my $metapkg = meta::package->get( "main" );

   is( $metapkg->get_symbol( '&func' )->reference, \&func,
      '$metapkg->get_symbol for code not confused by GV-less optimisation' );
}

# ->list_symbols
{
   my $metapkg = meta::package->get( "main" );
   my %metasyms = $metapkg->list_symbols;

   ok( $metasyms{'$VAR'}, '->list_symbols found $VAR' );
   ref_is( $metasyms{'$VAR'}->reference, \$VAR,
      '->list_symbols returned the correct $VAR' );

   ok( $metasyms{'@VAR'}, '->list_symbols found @VAR' );
   ref_is( $metasyms{'@VAR'}->reference, \@VAR,
      '->list_symbols returned the correct @VAR' );

   ok( $metasyms{'&func'}, '->list_symbols found &func via GV-less optimisation' );
   ref_is( $metasyms{'&func'}->reference, \&func,
      '->list_symbols returned the correct &func' );

   %metasyms = $metapkg->list_symbols( sigils => '$' );
   ok( !$metasyms{'@VAR'}, '->list_symbols sigil filtering omits array' );
}

done_testing;
