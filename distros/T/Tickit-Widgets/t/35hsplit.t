#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::HSplit;

my $win = mk_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } qw( A B );

my $widget = Tickit::Widget::HSplit->new
   ->set_top_child    ( $statics[0] )
   ->set_bottom_child ( $statics[1] );

ok( defined $widget, 'defined $widget' );

is( scalar $widget->children, 2, '$widget has 2 children' );

ref_is( $widget->top_child,    $statics[0], '$widget->top_child is $statics[0]' );
ref_is( $widget->bottom_child, $statics[1], '$widget->bottom_child is $statics[1]' );

is( $widget->lines, 3, '$widget->lines is 3' );
is( $widget->cols,  8, '$widget->cols is 8' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after $widget->set_window' );

flush_tickit;

is_display( [ [TEXT("Widget A")], BLANKLINES(11),
              [TEXT("─"x80,bg=>4,fg=>7)],
              [TEXT("Widget B")], BLANKLINES(11) ],
            'Display initially' );

$widget->set_style( spacing => 4 );

flush_tickit;

is_display( [ [TEXT("Widget A")], BLANKLINES(10),
              [TEXT("─"x80,bg=>4,fg=>7)],
              BLANKLINES(2,bg=>4,fg=>7),
              [TEXT("─"x80,bg=>4,fg=>7)],
              [TEXT("Widget B")], BLANKLINES(10) ],
            'Display after ->set_style spacing' );

pressmouse( press   => 1, 12, 39 );
pressmouse( drag    => 1,  6, 39 );
pressmouse( release => 1,  6, 39 );

flush_tickit;

is_display( [ [TEXT("Widget A")], BLANKLINES(4),
              [TEXT("─"x80,bg=>4,fg=>7)],
              BLANKLINES(2,bg=>4,fg=>7),
              [TEXT("─"x80,bg=>4,fg=>7)],
              [TEXT("Widget B")], BLANKLINES(16) ],
            'Display after mouse drag reshape' );

done_testing;
