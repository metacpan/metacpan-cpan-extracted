#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use meta;
no warnings qw( meta::experimental );

sub testfunc ($$@) { }

{
   my $metasub = meta::package->get( "main" )->get_symbol( '&testfunc' );
   isa_ok( $metasub, [ "meta::subroutine" ], '$metasub isa meta subroutine' );

   ok( $metasub->is_subroutine, '$metasub->is_subroutine' );

   is( $metasub->subname, "main::testfunc",
      '$metasub->subname' );
   is( $metasub->prototype, '$$@',
      '$metasub->prototype' );

   $metasub = meta::for_reference( \&testfunc );

   ok( $metasub->is_subroutine, '$metasub for reference ->is_subroutine' );

   ref_is( $metasub->reference, \&testfunc,
      'meta::for_reference ARRAY yields metasub' );
}

sub to_be_modified { }

{
   my $metasub = meta::package->get( "main" )->get_symbol( '&to_be_modified' );

   $metasub->set_subname( "a-new-name-here" );  # does not have to be valid
   is( $metasub->subname, "main::a-new-name-here",
      '$metasub->subname after ->set_subname' );

   $metasub->set_subname( "different::package::name" );
   is( $metasub->subname, "different::package::name",
      '$metasub->subname after ->set_subname on different package' );

   $metasub->set_prototype( '$$' );
   is( $metasub->prototype, '$$',
      '$metasub->prototype after ->set_prototype' );
}

done_testing;
