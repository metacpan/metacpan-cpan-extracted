#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Refcount;
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

isa_ok( $tickit, 'Tickit::Async', '$tickit' );
is_oneref( $tickit, '$tickit has refcount 1 initially' );

$loop->add( $tickit );

is_refcount( $tickit, 2, '$tickit has refcount 2 after $loop->add' );

{
   my $later;
   $tickit->later( sub { $later++ } );

   $loop->loop_once( 1 );

   is( $later, 1, '$later 1 after ->later' );
}

is_refcount( $tickit, 2, '$tickit has refcount 2 before $loop->remove' );

$loop->remove( $tickit );

is_oneref( $tickit, '$tickit has refcount 1 at EOF' );

done_testing;
