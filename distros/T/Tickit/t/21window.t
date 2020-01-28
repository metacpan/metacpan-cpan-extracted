#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Tickit::Test;

my ( $term, $rootwin ) = mk_term_and_window;

is_refcount( $rootwin, 1, '$rootwin has refcount 1 initially' );

my $win = $rootwin->make_sub( 3, 10, 4, 20 );
flush_tickit;

is_oneref( $win, '$win has refcount 1 initially' );

is( "$win", 'Tickit::Window[20x4 abs@10,3]', '$win string overload' );
ok( $win != $rootwin, '$win numeric comparison compares object identities' );

isa_ok( $win, "Tickit::Window", '$win isa Tickit::Window' );

is( $win->top,   3, '$win->top' );
is( $win->left, 10, '$win->left' );

is( $win->abs_top,   3, '$win->abs_top' );
is( $win->abs_left, 10, '$win->abs_left' );

is( $win->lines,  4, '$win->lines' );
is( $win->cols,  20, '$win->cols' );

is( $win->bottom,  7, '$win->bottom' );
is( $win->right,  30, '$win->right' );

isa_ok( my $rect = $win->rect, "Tickit::Rect", '$win->rect' );
is( $rect->top,     3, '$win->rect->top' );
is( $rect->left,   10, '$win->rect->left' );
is( $rect->bottom,  7, '$win->rect->bottom' );
is( $rect->right,  30, '$win->rect->right' );

cmp_ok( $win->parent, '==', $rootwin, '$win->parent' );
cmp_ok( $win->root,   '==', $rootwin, '$win->root' );

cmp_ok( $win->tickit, '==', $rootwin->tickit, '$win->tickit' );

is_deeply( [ $rootwin->subwindows ],
           [ $win ], '$rootwin->subwindows' );

is_deeply( [ $win->subwindows ],
           [], '$win->subwindows' );

isa_ok( $win->term, "Tickit::Term", '$win->term' );

# geometry change event
{
   my $geom_changed = 0;
   $win->bind_event( geomchange => sub { $geom_changed++ } );

   is( $geom_changed, 0, '$reshaped is 0 before resize' );

   $win->resize( 4, 15 );

   is( $win->lines, 4, '$win->lines is 4 after resize' );
   is( $win->cols, 15, '$win->cols is 15 after resize' );

   is( $geom_changed, 1, '$reshaped is 1 after resize' );

   $win->reposition( 5, 15 );

   is( $win->top,   5, '$win->top after reposition' );
   is( $win->left, 15, '$win->left after reposition' );

   is( $win->abs_top,   5, '$win->abs_top after reposition' );
   is( $win->abs_left, 15, '$win->abs_left after reposition' );

   is( $geom_changed, 2, '$reshaped is 2 after reposition' );
}

# sub-window nesting
{
   my $subwin = $win->make_sub( 2, 2, 1, 10 );
   flush_tickit;

   is( $subwin->top,  2, '$subwin->top' );
   is( $subwin->left, 2, '$subwin->left' );

   is( $subwin->abs_top,   7, '$subwin->abs_top' );
   is( $subwin->abs_left, 17, '$subwin->abs_left' );

   is( $subwin->lines,  1, '$subwin->lines' );
   is( $subwin->cols,  10, '$subwin->cols' );

   cmp_ok( $subwin->parent, '==', $win, '$subwin->parent' );
   cmp_ok( $subwin->root,   '==', $rootwin, '$subwin->root' );

   isa_ok( $subwin->term, "Tickit::Term", '$subwin->term' );

   is_refcount( $win, 1, '$win has refcount 1 at EOF' );

   $subwin->close; undef $subwin;
   $win->close; undef $win;
   flush_tickit;
}

is_refcount( $rootwin, 1, '$rootwin has refcount 1 at EOF' );

done_testing;
