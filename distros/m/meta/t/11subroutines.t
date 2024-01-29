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
}

done_testing;
