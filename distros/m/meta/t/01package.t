#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

# meta::package->get
{
   my $metapkg = meta::package->get( "meta" );
   ok( $metapkg, 'meta::package->get for "meta"' );

   is( $metapkg->name, "meta", 'Name of package' );
}

# Test2::V0's metapackage
{
   is( meta::package->get( "Test2::V0" )->name, "Test2::V0",
      'Name of the Test2::V0 package' );
}

# missing gets created
{
   my $metapkg;
   ok( lives { $metapkg = meta::package->get( "this-is-not-a-package" ) },
      'get_package creates a new package' );
   is( $metapkg->name, "this-is-not-a-package" );
}

# Older meta::get_package function interface
{
   my $metapkg = meta::get_package( "meta" );
   ok( $metapkg, 'meta::get_package for "meta"' );

   is( $metapkg->name, "meta", 'Name of package' );
}

# this file's main package
{
   is( meta::get_this_package()->name, "main",
      'Name of the main package from get_this_package' );
}

# subpackages
{
   my %sub_metapkgs = meta::get_package( "meta" )->list_subpackages;
   ok( keys %sub_metapkgs, '->list_subpackages returned some entries' );

   ok( my $package_metapkg = $sub_metapkgs{"package"},
      'subpackage for "package" exists' );
   is( $package_metapkg->name, "meta::package", 'name of "package" subpackage' );
}

done_testing;
