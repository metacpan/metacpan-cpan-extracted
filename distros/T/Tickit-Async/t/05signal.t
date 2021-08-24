#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Tickit::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $my_rd, $term_wr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
$term_wr->blocking(0);

my $tickit = Tickit::Async->new(
   term_out => $term_wr,
);

$loop->add( $tickit );

# signal
{
   my $caught;
   $tickit->watch_signal( POSIX::SIGHUP(), sub { $caught++ } );

   kill HUP => $$;

   wait_for { $caught };
   is( $caught, 1, '$caught 1 after raise SIGHUP' );
}

done_testing;
