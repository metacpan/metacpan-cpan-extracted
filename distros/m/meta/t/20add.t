#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

my $metapkg = meta::package->get( "main" );

# add scalar
{
   my $var = 1234;

   my $metasym = $metapkg->add_symbol( '$NEW_SCALAR', \$var );
   ok( $metasym, '->add_symbol returned metasym' );

   is( eval('$main::NEW_SCALAR'), 1234,
      'New scalar appears in package' );
   ref_is( $metasym->reference, \$var,
      '$metasym->reference for scalar' );

   like( dies { $metapkg->add_symbol( '$NEW_SCALAR', \my $tmp ) },
      qr/^Package "main" already contains a symbol named "\$NEW_SCALAR" /,
      '->add_symbol on same name throws exception' );

   is( $metapkg->add_symbol( '$BLANK_SCALAR' )->reference, \undef,
      'New blank scalar' );
}

# get_or_add scalar
{
   my $metasym = $metapkg->get_or_add_symbol( '$SCALAR1' );
   ok( $metasym, '->get_or_add_symbol returned metasym' );

   ${ $metasym->reference } = 1235;
   is( eval('$main::SCALAR1'), 1235,
      'New scalar appears in package' );
}

# add array
{
   my @var = ( 56, 78 );

   my $metasym = $metapkg->add_symbol( '@NEW_ARRAY', \@var );
   ok( $metasym, '->add_symbol returned metasym' );

   is( [ eval('@main::NEW_ARRAY') ], [ 56, 78 ],
      'New array appears in package' );
   ref_is( $metasym->reference, \@var,
      '$metasym->reference for array' );

   is( $metapkg->add_symbol( '@BLANK_ARRAY' )->reference, [],
      'New blank array' );
}

# get_or_add array
{
   my $metasym = $metapkg->get_or_add_symbol( '@ARRAY1' );
   ok( $metasym, '->get_or_add_symbol returned metasym' );

   push @{ $metasym->reference }, 57;
   is( [ eval('@main::ARRAY1') ], [ 57 ],
      'New array appears in package' );
}

# add hash
{
   my %var = ( nine => 10 );

   my $metasym = $metapkg->add_symbol( '%NEW_HASH', \%var );
   ok( $metasym, '->add_symbol returned metasym' );

   is( { eval('%main::NEW_HASH') }, { nine => 10 },
      'New hash appears in package' );
   is( $metasym->reference, \%var,
      '$metasym->reference for hash' );

   is( $metapkg->add_symbol( '%BLANK_HASH' )->reference, {},
      'New blank hash' );
}

# get_or_add hash
{
   my $metasym = $metapkg->get_or_add_symbol( '%HASH1' );
   ok( $metasym, '->get_or_add_symbol returned metasym' );

   ${ $metasym->reference }{ten} = 11;
   is( { eval('%main::HASH1') }, { ten => 11 },
      'New hash appears in package' );
}

# add code
{
   my $sub = sub { return "the function" };

   my $metasym = $metapkg->add_symbol( '&NEW_SUB', $sub );
   ok( $metasym, '->add_symbol returned metasym' );

   is( eval('main::NEW_SUB()'), "the function",
      'New function appears in package' );
   is( $metasym->reference, $sub,
      '$metasym->reference for function' );
}

# multiple slots can be added at once without clashing
{
   my $metascalar = $metapkg->add_symbol( '$SHARED', \my $tmp );
   my $metaarray  = $metapkg->add_symbol( '@SHARED', \my @tmp );
   my $metahash   = $metapkg->add_symbol( '%SHARED', \my %tmp );

   ok( eval( '
      $::SHARED = "scalar";
      @::SHARED = ( "array" );
      %::SHARED = ( hash => undef );
   ' ), 'new variables can be written' )
      or diag $@;

   is( \$tmp, \"scalar",       'Scalar written to' );
   is( \@tmp, ["array"],       'Array written to' );
   is( \%tmp, {hash => undef}, 'Hash written to' );
}

sub func { "toplevel func" }

# Can add a slot around a GV-less optimised symbol table entry
{
   $metapkg->add_symbol( '$func', \my $var );
   $var = 123;

   is( main->can( "func" )->(), "toplevel func",
      'Toplevel func still works after adding var called $func' );
}

done_testing;
