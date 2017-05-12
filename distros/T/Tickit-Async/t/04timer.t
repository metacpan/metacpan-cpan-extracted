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

my $tickit = Tickit::Async->new(
   term_out => $term_wr,
);

$loop->add( $tickit );

{
   my $tick;
   $tickit->timer( after => 0.1, sub { $tick++ } );

   wait_for { $tick };
   is( $tick, 1, '$tick 1 after "after" timer' );

   $tickit->timer( at => time() + 0.1, sub { $tick++ } );

   wait_for { $tick == 2 };
   is( $tick, 2, '$tick 2 after "at" timer' );
}

done_testing;
