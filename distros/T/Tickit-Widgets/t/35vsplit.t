#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::VSplit;

my $win = mk_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } qw( A B );

my $widget = Tickit::Widget::VSplit->new(
   left_child => $statics[0],
   right_child => $statics[1],
);

ok( defined $widget, 'defined $widget' );

is( scalar $widget->children, 2, '$widget has 2 children' );

identical( $widget->left_child,  $statics[0], '$widget->left_child is $statics[0]' );
identical( $widget->right_child, $statics[1], '$widget->right_child is $statics[1]' );

is( $widget->lines,  1, '$widget->lines is 1' );
is( $widget->cols,  17, '$widget->cols is 17' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after $widget->set_window' );

flush_tickit;

is_display( [ [TEXT("Widget A"), BLANK(32), TEXT("│",bg=>4,fg=>7), TEXT("Widget B"), BLANK(31)],
              map { [BLANK(40), TEXT("│",bg=>4,fg=>7), BLANK(39)] } 2 .. 25 ],
            'Display initially' );

$widget->set_style( spacing => 4 );

flush_tickit;

is_display( [ [TEXT("Widget A"), BLANK(30), TEXT("│  │",bg=>4,fg=>7), TEXT("Widget B"), BLANK(30)],
              map { [BLANK(38), TEXT("│  │",bg=>4,fg=>7), BLANK(38)] } 2 .. 25 ],
            'Display after ->set_style spacing' );

pressmouse( press   => 1, 5, 39 );
pressmouse( drag    => 1, 5, 30 );
pressmouse( release => 1, 5, 30 );

flush_tickit;

is_display( [ [TEXT("Widget A"), BLANK(21), TEXT("│  │",bg=>4,fg=>7), TEXT("Widget B"), BLANK(39)],
              map { [BLANK(29), TEXT("│  │",bg=>4,fg=>7), BLANK(47)] } 2 .. 25 ],
            'Display after mouse drag reshape' );

done_testing;
