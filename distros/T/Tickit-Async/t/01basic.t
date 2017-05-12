#!/usr/bin/perl

use strict;
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

{
   my $sigwinch;

   no warnings 'redefine';
   local *Tickit::_SIGWINCH = sub {
      $sigwinch++;
   };

   kill SIGWINCH => $$;

   $loop->loop_once( 1 );

   is( $sigwinch, 1, '$sigwinch 1 after raise SIGWINCH' );
}

is_refcount( $tickit, 2, '$tickit has refcount 2 before $loop->remove' );

$loop->remove( $tickit );

is_oneref( $tickit, '$tickit has refcount 1 at EOF' );

done_testing;
