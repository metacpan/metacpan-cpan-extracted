#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::VBox;

my ( $term, $win ) = mk_term_and_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 0 .. 2;

my $widget = Tickit::Widget::VBox->new;

ok( defined $widget, 'defined $widget' );

is( scalar $widget->children, 0, '$widget has 0 children' );

$widget->add( $_ ) for @statics;

is( scalar $widget->children, 3, '$widget has 3 children after adding' );

is( $widget->lines, 3, '$widget->lines is 3' );
is( $widget->cols, 8, '$widget->cols is 8' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after ->set_window $win' );
ok( defined $statics[1]->window, '$statics[1] has window after ->set_window $win' );
ok( defined $statics[2]->window, '$statics[2] has window after ->set_window $win' );
is( "".$statics[0]->window, 'Tickit::Window[80x1 abs@0,0]', '$statics[0] has correct window' );
is( "".$statics[1]->window, 'Tickit::Window[80x1 abs@0,1]', '$statics[1] has correct window' );
is( "".$statics[2]->window, 'Tickit::Window[80x1 abs@0,2]', '$statics[2] has correct window' );

flush_tickit;

is_display( [ [TEXT("Widget 0")],
              [TEXT("Widget 1")],
              [TEXT("Widget 2")] ],
            'Display initially' );

$widget->set_child_opts( 1, expand => 1 );

flush_tickit;

is_display( [ [TEXT("Widget 0")],
              [TEXT("Widget 1")],
              BLANKLINES(22),
              [TEXT("Widget 2")] ],
            'Display after expand change' );

$statics[0]->set_text( "A longer piece of text for the static" );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static")],
              [TEXT("Widget 1")],
              BLANKLINES(22),
              [TEXT("Widget 2")] ],
            'Display after static text change' );

resize_term( 30, 100 );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static")],
              [TEXT("Widget 1")],
              BLANKLINES(27),
              [TEXT("Widget 2")] ],
            'Display after resize' );

$widget->add( Tickit::Widget::Static->new( text => "New Widget" ) );

is( scalar $widget->children, 4, '$widget now has 4 children after new widget' );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static")],
              [TEXT("Widget 1")],
              BLANKLINES(26),
              [TEXT("Widget 2")],
              [TEXT("New Widget")] ],
            'Display after new widget' );

$widget->set_child_opts( 2, force_size => 3 );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static"), TEXT("")],
              [TEXT("Widget 1"), TEXT("")],
              BLANKLINES(24),
              [TEXT("Widget 2"), TEXT("")],
              BLANKLINES(2),
              [TEXT("New Widget"), TEXT("")] ],
            'Display after force_size' );

$widget->set_child( 0, Tickit::Widget::Static->new( text => "A new Static" ) );

flush_tickit;

is_display( [ [TEXT("A new Static"), TEXT("")],
              [TEXT("Widget 1"), TEXT("")],
              BLANKLINES(24),
              [TEXT("Widget 2"), TEXT("")],
              BLANKLINES(2),
              [TEXT("New Widget"), TEXT("")] ],
            'Display after force_size' );

$widget->set_window( undef );

ok( !defined $statics[0]->window, '$static has no window after ->set_window undef' );

done_testing;
