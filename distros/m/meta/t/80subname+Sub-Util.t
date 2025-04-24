#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

# This is a core module since 5.22
use Test2::Require::Module 'Sub::Util';
use Sub::Util;

# Values set by Sub::Util are readable by meta
{
   my $testsub =
      Sub::Util::set_subname   name_of_the_sub =>
      Sub::Util::set_prototype '&$$@' =>
      sub { ... };

   my $metasub = meta::for_reference( $testsub );

   is( $metasub->subname, "main::name_of_the_sub",
      '$metasub->subname from Sub::Util::set_subname' );
   is( $metasub->prototype, '&$$@',
      '$metasub->prototype from Sub::Util::set_prototype' );
}

# Values set by meta are readable by Sub::Util
{
   # ensure this is a real closure so it's unique
   my $testsub = meta::for_reference( do { my $x; sub { $x } } )
      ->set_subname( 'name_of_the_sub' )
      ->set_prototype( '&$$@' )
      ->reference;

   is( Sub::Util::subname( $testsub ), 'main::name_of_the_sub',
      'Sub::Util::subname from $metasub->set_subname' );
   is( Sub::Util::prototype( $testsub ), '&$$@',
      'Sub::Util::prototype from $metasub->set_prototype' );
}

done_testing;
