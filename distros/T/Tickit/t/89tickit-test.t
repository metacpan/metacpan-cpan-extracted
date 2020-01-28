#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Time::HiRes qw( time );

my $tickit = mk_tickit;

isa_ok( $tickit, "Tickit", '$tickit' );

isa_ok( $tickit->term, "Tickit::Term", '$tickit->term' );
isa_ok( $tickit->rootwin, "Tickit::Window", '$tickit->rootin' );

# TODO: IO will be difficult to mock

# timer
{
   my $called;
   $tickit->watch_timer_after( 0.1, sub { $called++ } );

   flush_tickit;

   ok( !$called, '->watch_timer_after not yet invoked' );

   flush_tickit 0.5;

   ok( $called, '->watch_timer_after now invoked callback' );

   undef $called;
   $tickit->watch_timer_at( time + 0.2, sub { $called++ } );

   flush_tickit;

   ok( !$called, '->watch_timer_at not yet invoked' );

   flush_tickit 0.5;

   ok( $called, '->watch_timer_at now invoked callback' );
}

# timer cancellation
{
   my $called;
   my $id = $tickit->watch_timer_after( 0.2, sub { $called++ } );
   $tickit->watch_cancel( $id );

   flush_tickit 0.5;

   ok( !$called, '->watch_timer_after does not invoke after cancel' );
}

# later
{
   my $called;
   $tickit->watch_later( sub { $called++ } );

   flush_tickit;

   ok( $called, '->watch_later invokes callback' );
}

# later cancellation
{
   my $called;
   my $id = $tickit->watch_later( sub { $called++ } );
   $tickit->watch_cancel( $id );

   flush_tickit;

   ok( !$called, '->watch_later does not invoke after cancel' );
}

done_testing;
