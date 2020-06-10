#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::OS;

use Time::HiRes qw( time );

use Tickit::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $my_rd, $term_wr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
$term_wr->blocking(0);

my $tickit = Tickit::Async->new(
   term_out => $term_wr,
);

$loop->add( $tickit );

# timer
{
   my $tick;
   $tickit->timer( after => 0.1, sub { $tick++ } );

   wait_for { $tick };
   is( $tick, 1, '$tick 1 after "after" timer' );

   $tickit->timer( at => time() + 0.1, sub { $tick++ } );

   wait_for { $tick == 2 };
   is( $tick, 2, '$tick 2 after "at" timer' );
}

# cancel_timer
{
   my $now = time;

   my $done;
   $tickit->timer( at => $now + 0.2, sub { $done++ } );

   my $called;
   my $id = $tickit->timer( at => $now + 0.1, sub { $called++ } );
   $tickit->cancel_timer( $id );

   wait_for { $done };
   ok( !$called, '->cancel_timer removes pending timer' );
}

done_testing;
