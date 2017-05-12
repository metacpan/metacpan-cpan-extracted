#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Refcount;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::ScrollBox;

my $win = mk_window;

my $static = Tickit::Widget::Static->new(
   text => join "\n", map { "Content on line $_:" . join ",", 1 .. 50 } 1 .. 10
);

my $widget = Tickit::Widget::ScrollBox->new(
   horizontal => 1,
   vertical   => 0,
);

ok( defined $widget, 'defined $widget' );
is_oneref( $widget, '$widget has refcount 1 initially' );

$widget->add( $static );

is_oneref( $widget, '$widget has refcount 1 after adding child' );

is( $widget->lines,  11, '$widget wants 11 lines' );
is( $widget->cols,  159, '$widget wants 159 cols' );

my $hextent = $widget->hextent;

ok( defined $hextent, '$widget has ->hextent' );

$widget->set_window( $win );

ok( defined $static->window, '$static has window after $widget->set_window' );

is( $static->window->top,     0, '$static window starts on line 0' );
is( $static->window->left,    0, '$static window starts on column 0' );
is( $static->window->lines,  24, '$static given 24 line window' );
is( $static->window->cols,  159, '$static given 159 column window' );

is( $hextent->total,   159, '$hextent->total is 159' );
is( $hextent->viewport, 80, '$hextent->viewport is 80' );
is( $hextent->start,     0, '$hextent->start is 0' );

flush_tickit;

is_display( [ ( map +[TEXT("Content on line $_:" . join( ",", 1 .. 24 ) )], 1 .. 9 ),
              ( map +[TEXT("Content on line $_:" . join( ",", 1 .. 23 ) . ",2" )], 10 ),
              BLANKLINES(14),
              [TEXT(" ",rv=>1),
               BLANK(39,bg=>4),
               TEXT("═"x39,fg=>4),
               TEXT("\x{25B8}",rv=>1)] ],
            'Display initially' );

$widget->scroll( undef, +10 );
flush_tickit;

is( $static->window->left, -10, '$static window starts on column -10 after ->scroll +10' );
is( $hextent->start, 10, '$hextent->start is now 10 after ->scroll +10' );

is_display( [ ( map +[TEXT(" line $_:" . join( ",", 1 .. 27 ) . "," )], 1 .. 9 ),
              ( map +[TEXT(" line $_:" . join( ",", 1 .. 27 ) )], 10 ),
              BLANKLINES(14),
              [TEXT("\x{25C2}",rv=>1),
               TEXT("═"x5,fg=>4),
               BLANK(39,bg=>4),
               TEXT("═"x34,fg=>4),
               TEXT("\x{25B8}",rv=>1)] ],
            'Display after scroll +10' );

$hextent->scroll_to( 25 );
flush_tickit;

is( $static->window->left, -25, '$static window starts on column -10 after ->scroll_to 25' );
is( $hextent->start, 25, '$hextent->start is now 10 after ->scroll_to 25' );

is_display( [ ( map +[TEXT("," . join( ",", 5 .. 32 ) . "," )], 1 .. 9 ),
              ( map +[TEXT(join( ",", 4 .. 32 ) )], 10 ),
              BLANKLINES(14),
              [TEXT("\x{25C2}",rv=>1),
               TEXT("═"x12,fg=>4),
               BLANK(39,bg=>4),
               TEXT("═"x27,fg=>4),
               TEXT("\x{25B8}",rv=>1)] ],
            'Display after $vextent->scroll_to 25' );

is_oneref( $widget, '$widget has refcount 1 at EOF' );

done_testing;
