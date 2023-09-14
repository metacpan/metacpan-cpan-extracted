#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Tickit qw( RUN_NOHANG );
use Time::HiRes qw( sleep );
use POSIX ();

pipe my( $term_rd, $my_wr ) or die "Cannot pipepair - $!";
pipe my( $my_rd, $term_wr ) or die "Cannot pipepair - $!";

my $tickit = Tickit->new(
   term_in  => $term_rd,
   term_out => $term_wr,
);

$tickit->tick( RUN_NOHANG );

# post-exit
{
   my $status;

   my $pid = fork();
   if( !$pid ) {
      sleep( 0.1 );
      POSIX::_exit( 5 );
   }

   $tickit->watch_process( $pid, sub { $status = $_[0]->wstatus } );

   $tickit->tick( 0 );

   is( POSIX::WEXITSTATUS($status), 5, '$status after child terminated' );
}

done_testing;
