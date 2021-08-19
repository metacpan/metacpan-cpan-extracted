#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN {
   # We need to force TERM=xterm so that we can guarantee the right byte
   # sequences for testing
   $ENV{TERM} = "xterm";
}

use Test::More;

use Tickit::Term;

my $term = Tickit::Term->new();
$term->set_size( 25, 80 );

{
   is( $term->lines, 25, '$term->lines 25 initially' );
   is( $term->cols,  80, '$term->cols 80 initially' );

   my ( $lines, $cols );
   my $id = $term->bind_event( resize => sub {
      my ( undef, $ev, $info ) = @_;
      cmp_ok( $_[0], '==', $term, '$_[0] is term for resize event' );
      is( $ev, "resize", '$ev is resize for resize event' );
      $lines = $info->lines;
      $cols  = $info->cols;
   } );

   ok( defined $id, '$id defined for $term->bind_event' );

   $term->set_size( 30, 100 );

   is( $term->lines,  30, '$term->lines 30 after set_size' );
   is( $term->cols,  100, '$term->cols 100 after set_size' );

   is( $lines,  30, '$lines to bind_event sub after set_size' );
   is( $cols,  100, '$cols to bind_event sub after set_size' );

   $term->unbind_event_id( $id );
}

done_testing;
