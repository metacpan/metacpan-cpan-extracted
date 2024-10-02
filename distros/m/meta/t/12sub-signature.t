#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.26 or
      plan skip_all => "Not supported on Perl $^V";
}

use meta;
no warnings qw( meta::experimental );

use experimental 'signatures';

sub testfunc ( $x, $y, $z = undef ) { ... }

sub testfunc_with_array ( $first, @rest ) { ... }
sub testfunc_with_hash  ( $first, %rest ) { ... }

my $mainpkg = meta::package->get( "main" );

{
   my $metasub = $mainpkg->get_symbol( '&testfunc' );

   my $metasig = $metasub->signature;
   ok( $metasig, '$metasub->signature yields something' );

   is( $metasig->mandatory_params, 2, 'signature has 2 mandatory params' );
   is( $metasig->optional_params,  1, 'signature has 1 optional param' );
   is( $metasig->slurpy, undef,       'signature has no slurpy param' );

   is( $metasig->min_args, 2, 'signature requires at least 2 argument values' );
   is( $metasig->max_args, 3, 'signature supports at most 3 argument values' );

   $metasig = meta::for_reference( sub ( $x ) { } )->signature;
   ok( $metasig, '$metasig for anonymous CODE reference' );
   is( $metasig->mandatory_params, 1, 'anon code signature has 1 mandatory param' );
}

# subs with slurpy
{
   my $metasig = $mainpkg->get_symbol( '&testfunc_with_array' )->signature;

   is( $metasig->slurpy, '@', 'signature slurpy array' );

   is( $metasig->min_args, 1, 'signature with slurpy array requires at least 1 argument value' );
   is( $metasig->max_args, undef, 'signature with slurpy array supports unbounded argument values' );

   is( $mainpkg->get_symbol( '&testfunc_with_hash' )->signature->slurpy, '%',
      'signature slurpy hash' );
}

sub func_no_sig { }

{
   my $metasub = $mainpkg->get_symbol( '&func_no_sig' );

   ok( !$metasub->signature, '$metasub for non-signatured sub has no signature' );
}

done_testing;
