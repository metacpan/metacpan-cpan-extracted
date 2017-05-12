#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Test;

my ( $term, $win ) = mk_term_and_window;

isa_ok( $win, "Tickit::Window", '$win isa Tickit::Window' );

# Already 2 references; Tickit object keeps a permanent one, and we have one
# here. This is fine.
is_refcount( $win, 2, '$win has refcount 2 initially' );

is( $win->top,  0, '$win->top is 0' );
is( $win->left, 0, '$win->left is 0' );

is( $win->abs_top,  0, '$win->abs_top is 0' );
is( $win->abs_left, 0, '$win->abs_left is 0' );

is( $win->lines, 25, '$win->lines is 25' );
is( $win->cols,  80, '$win->cols is 80' );

isa_ok( $win->term, "Tickit::Term", '$win->term' );

isa_ok( $win->tickit, "Tickit", '$win->tickit' );

# window pen
{
   isa_ok( $win->pen, "Tickit::Pen", '$win->pen isa Tickit::Pen' );

   is_deeply( { $win->pen->getattrs },
              {},
              '$win->pen has no attrs set' );

   is( $win->getpenattr( 'fg' ), undef, '$win has pen fg undef' );

   is_deeply( { $win->get_effective_pen->getattrs },
              {},
              '$win->get_effective_pen has no attrs set' );

   is( $win->get_effective_penattr( 'fg' ), undef, '$win has effective pen fg undef' );

   $win->pen->chattr( fg => 3 );

   is_deeply( { $win->pen->getattrs },
              { fg => 3 },
              '$win->pen->getattrs has fg => 3' );

   is( $win->getpenattr( 'fg' ), 3, '$win has pen fg 3' );

   is_deeply( { $win->get_effective_pen->getattrs },
              { fg => 3 },
              '$win->get_effective_pen has fg => 3' );

   is( $win->get_effective_penattr( 'fg' ), 3, '$win has effective pen fg 3' );

   my $newpen = Tickit::Pen->new;
   $newpen->chattr( fg => 3 );
   $newpen->chattr( u => 1 );

   $win->set_pen( $newpen );

   is_deeply( { $win->pen->getattrs },
              { fg => 3, u => 1 },
              '$win->set_pen replaces window pen' );

   $win->pen->chattr( u => undef );
}

# scrolling
{
   ok( $win->scroll( 1, 0 ), '$win can ->scroll' );

   is_termlog( [ SETBG(undef),
                 SCROLLRECT(0,0,25,80, 1,0) ],
               'Termlog scrolled' );

   $win->scrollrect( Tickit::Rect->new( top => 5, left => 0, lines => 10, cols => 80 ),
                     3, 0 );

   is_termlog( [ SETBG(undef),
                 SCROLLRECT(5,0,10,80, 3,0) ],
               'Termlog after scrollrect' );

   $win->scrollrect( Tickit::Rect->new( top => 20, left => 0, lines => 1, cols => 80 ),
                     0, 1 );

   is_termlog( [ SETBG(undef),
                 SCROLLRECT(20,0,1,80, 0,1) ],
               'Termlog after scrollrect rightward' );

   $win->scrollrect( Tickit::Rect->new( top => 21, left => 10, lines => 1, cols => 70 ),
                     0, -1 );
   flush_tickit;

   is_termlog( [ SETBG(undef),
                 SCROLLRECT(21,10,1,70, 0,-1) ],
               'Termlog after scrollrect leftward not fullwidth' );
}

# Scrolling region exposure
{
   my @exposed_rects;
   $win->bind_event( expose => sub { push @exposed_rects, $_[2]->rect } );

   $win->scroll( 1, 0 );
   flush_tickit;

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top => 24, bottom => 25, left => 0, right => 80 ) ],
              'Exposed area after ->scroll downward' );
   undef @exposed_rects;

   $win->scroll( -1, 0 );
   flush_tickit;

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top => 0, bottom => 1, left => 0, right => 80 ) ],
              'Exposed area after ->scroll upward' );
   undef @exposed_rects;

   $win->scroll( 0, 1 );
   flush_tickit;

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top => 0, bottom => 25, left => 79, right => 80 ) ],
              'Exposed area after ->scroll rightward' );
   undef @exposed_rects;

   $win->scroll( 0, -1 );
   flush_tickit;

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top => 0, bottom => 25, left => 0, right => 1 ) ],
              'Exposed area after ->scroll leftward' );
   undef @exposed_rects;

   # Test that ->scroll updates pending damage

   $win->expose( Tickit::Rect->new( top => 10, bottom => 12, left => 0, right => 80 ) );
   $win->scroll( 2, 0 );
   flush_tickit;

   is_deeply( \@exposed_rects,
              [ Tickit::Rect->new( top => 8, bottom => 10, left => 0, right => 80 ),
                Tickit::Rect->new( top => 23, bottom => 25, left => 0, right => 80 ) ],
              'Damage area updated after ->scroll' );

   drain_termlog;
}

# geometry change event
{
   my $geom_changed = 0;
   $win->bind_event( geomchange => sub { $geom_changed++ } );

   is( $geom_changed, 0, '$reshaped is 0 before term resize' );

   resize_term( 30, 100 );

   is( $win->lines, 30, '$win->lines is 30 after term resize' );
   is( $win->cols, 100, '$win->cols is 100 after term resize' );

   is( $geom_changed, 1, '$reshaped is 1 after term resize' );
}

is_refcount( $win, 2, '$win has refcount 2 before dropping Tickit' );

done_testing;
