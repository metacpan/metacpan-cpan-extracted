#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Time::HiRes qw( time );

use Tickit;

pipe my( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

my $tickit = Tickit->new(
   term_in  => $term_rd,
   term_out => $term_wr,
);

# timer after
{
   my $now = time;

   my $called;
   $tickit->watch_timer_after( 0.1, sub { $called++ } );

   # because poll and gettimeofday aren't synchronised, this may not work the first time
   while( !$called ) {
      die "Test timed out" if time > $now + 2;
      $tickit->tick;
   }

   ok( $called, '->watch_timer_after invokes code block' );
}

# timer at
{
   my $now = time;

   my $called;
   $tickit->watch_timer_at( $now + 0.1, sub { $called++ } );

   # because poll and gettimeofday aren't synchronised, this may not work the first time
   while( !$called ) {
      die "Test timed out" if time > $now + 2;
      $tickit->tick;
   }

   ok( $called, '->watch_timer_at invokes code block' );
}

# watch_cancel
{
   my $now = time;

   my $done;
   $tickit->watch_timer_at(  $now + 0.2, sub { $done++ } );

   my $called;
   my $id = $tickit->watch_timer_at( $now + 0.1, sub { $called++ } );
   $tickit->watch_cancel( $id );

   while( !$done ) {
      die "Test timed out" if time > $now + 2;
      $tickit->tick;
   }

   ok( !$called, '->watch_cancel stops code block being invoked' );
}

done_testing;
