#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Tickit::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $my_rd, $term_wr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
$term_wr->blocking(0);

my $tickit = Tickit::Async->new(
   term_out => $term_wr,
);

$loop->add( $tickit );

# process
{
   my $status;

   my $pid = fork();
   if( !$pid ) {
      POSIX::_exit( 5 );
   }

   $tickit->watch_process( $pid, sub { $status = $_[0]->wstatus } );

   wait_for { defined $status };

   is( POSIX::WEXITSTATUS($status), 5, '$status after child terminated' );
}

done_testing;
