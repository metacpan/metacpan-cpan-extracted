#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Tickit qw( RUN_NOHANG );
use POSIX ();

pipe my( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

my $tickit = Tickit->new(
   term_in  => $term_rd,
   term_out => $term_wr,
);

# signal
{
   my $caught;
   $tickit->watch_signal( POSIX::SIGHUP(), sub { $caught++ } );

   kill HUP => $$;

   $tickit->tick( 0 );

   is( $caught, 1, '$caught 1 after raise SIGHUP' );
}

done_testing;
