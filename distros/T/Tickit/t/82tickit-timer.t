#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
   $tickit->timer( after => 0.1, sub { $called++ } );

   # because poll and gettimeofday aren't synchronised, this may not work the first time
   while( !$called ) {
      die "Test timed out" if time > $now + 2;
      $tickit->tick;
   }

   ok( $called, '->timer invokes code block' );
}

# cancel_timer
{
   my $now = time;

   my $done;
   $tickit->timer( at => $now + 0.2, sub { $done++ } );

   my $called;
   my $id = $tickit->timer( at => $now + 0.1, sub { $called++ } );
   $tickit->cancel_timer( $id );

   while( !$done ) {
      die "Test timed out" if time > $now + 2;
      $tickit->tick;
   }

   ok( !$called, '->cancel_timer stops code block being invoked' );
}

done_testing;
