#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit qw( RUN_NOHANG );

pipe my( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

my $tickit = Tickit->new(
   term_in  => $term_rd,
   term_out => $term_wr,
);

{
   my $called;
   $tickit->watch_later( sub { $called++ } );

   $tickit->tick;

   is( $called, 1, '->watch_later invokes callback' );
}

{
   my $called;
   my $id = $tickit->watch_later( sub { $called++ } );
   $tickit->watch_cancel( $id );

   $tickit->tick( RUN_NOHANG );

   ok( !$called, '->watch_cancel removes idle watch' );
}

done_testing;
