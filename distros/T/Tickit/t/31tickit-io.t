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

pipe my( $other_rd, $other_wr ) or die "Cannot pipepair - $!";

# io read
{
   # Make it readable
   $other_wr->syswrite( "Hello\n");

   my $called;
   my $watch = $tickit->watch_io( $other_rd, Tickit::IO_IN, sub {
      my ( $info ) = @_;
      $called++;
      is( $info->fd,   $other_rd->fileno, '$info->fd for invoked IO_IN callback' );
      is( $info->cond, Tickit::IO_IN,     '$info->cond for invoked IO_IN callback' );
   } );

   $tickit->tick;
   is( $called, 1, 'callback invoked for IO_IN' );

   $tickit->watch_cancel( $watch );
}

# io write
{
   my $called;
   my $watch = $tickit->watch_io( $other_wr, Tickit::IO_OUT, sub {
      my ( $info ) = @_;
      $called++;
      is( $info->fd,   $other_wr->fileno, '$info->fd for invoked IO_OUT callback' );
      is( $info->cond, Tickit::IO_OUT,    '$info->cond for invoked IO_OUT callback' );
   } );

   $tickit->tick;
   is( $called, 1, 'callback invoked for IO_OUT' );

   $tickit->watch_cancel( $watch );
}

# io hup
$other_wr->close; undef $other_wr;
{
   my $called;
   my $watch = $tickit->watch_io( $other_rd, Tickit::IO_HUP, sub {
      my ( $info ) = @_;
      $called++;
      is( $info->fd,   $other_rd->fileno, '$info->fd for invoked IO_HUP callback' );
      is( $info->cond, Tickit::IO_HUP,    '$info->cond for invoked IO_HUP callback' );
   } );

   $tickit->tick;
   is( $called, 1, 'callback invoked for IO_HUP' );

   $tickit->watch_cancel( $watch );
}

done_testing;
