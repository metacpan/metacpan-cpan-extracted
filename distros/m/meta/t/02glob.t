#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

{
   my $metapkg = meta::package->get( "meta" );
   my $metaglob = $metapkg->get_glob( "get_package" );
   ok( $metaglob, '$metapkg->get_glob on get_package' );

   is( $metaglob->basename, "get_package",
      '$metaglob->basename' );

   $metaglob = meta::for_reference( \*meta );

   ok( $metaglob->is_glob, '$metaglob for reference ->is_glob' );

   is( $metaglob->basename, "meta",
      '$metaglob from for_reference' );
}

# missing
{
   my $metapkg = meta::package->get( "meta" );
   ok( !defined $metapkg->try_get_glob( "not-a-glob" ),
      'try_get_glob yields undef on missing glob' );

   like( dies { $metapkg->get_glob( "not-a-glob" ) },
      qr/^Package "meta" does not contain a glob called "not-a-glob" /,
      'get_glob throws on missing glob' );
}

# meta::glob->get method
{
   my $metaglob = meta::glob->get( "meta::get_package" );
   ok( $metaglob, 'meta:;glob->get on meta::get_package' );

   is( $metaglob->basename, "get_package",
      '$metaglob->basename' );
}

# missing on methods
{
   ok( !defined meta::glob->try_get( "not-a-glob" ),
      'meta::glob->try_get yields undef on missing glob' );

   like( dies { meta::glob->get( "not-a-glob" ) },
      qr/^Symbol table does not contain a glob called "not-a-glob" /,
      'meta::glob->get throws on missing glob' );
}

# ->get_or_add
{
   ok( !defined meta::glob->try_get( "created-symbol" ),
      'created-symbol did not exist' );

   my $metaglob = meta::glob->get_or_add( "created-symbol" );
   ok( $metaglob, '->get_or_add returned metaglob' );
   is( $metaglob->basename, "created-symbol",
      'Name of newly-created symbol' );
   ok( defined meta::glob->try_get( "created-symbol" ),
      'created-symbol now exists' );
}

# ->list_*_globs
{
   my $metapkg = meta::package->get( "meta" );
   my @metaglobs = $metapkg->list_globs;

   # Don't be too sensitive to what globs we found
   ok( scalar @metaglobs, 'list_globs returned a list of globs' );
   ok( scalar( grep { $_->basename eq "get_package" } @metaglobs ),
      'list_globs result included a glob for "get_package"' );
   ok( !scalar( grep { $_->basename eq "package::" } @metaglobs ),
      'list_globs does not return subpackages' );

   my @metaglobs_pkgs = $metapkg->list_subpackage_globs;
   ok( scalar( grep { $_->basename eq "package::" } @metaglobs_pkgs ),
      'list_subpackage_globs returns subpackages' );

   my @metaglobs_all = $metapkg->list_all_globs;
   ok( @metaglobs + @metaglobs_pkgs == @metaglobs_all,
      'list_all_globs returns a list totalling the prior two' );
}

done_testing;
