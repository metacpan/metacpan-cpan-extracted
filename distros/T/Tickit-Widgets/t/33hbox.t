#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::HBox;

my ( $term, $win ) = mk_term_and_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 0 .. 2;

my $widget = Tickit::Widget::HBox->new(
   spacing => 2,
);

ok( defined $widget, 'defined $widget' );

is( scalar $widget->children, 0, '$widget has 0 children' );

$widget->add( $_ ) for @statics;

is( scalar $widget->children, 3, '$widget has 3 children after adding' );

is( $widget->lines, 1, '$widget->lines is 1' );
is( $widget->cols, 3*8 + 2*2, '$widget->cols is 3*8 + 2*2' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after ->set_window $win' );
ok( defined $statics[1]->window, '$statics[1] has window after ->set_window $win' );
ok( defined $statics[2]->window, '$statics[2] has window after ->set_window $win' );
is( "".$statics[0]->window, 'Tickit::Window[8x25 abs@0,0]', '$statics[0] has correct window' );
is( "".$statics[1]->window, 'Tickit::Window[8x25 abs@10,0]', '$statics[1] has correct window' );
is( "".$statics[2]->window, 'Tickit::Window[8x25 abs@20,0]', '$statics[2] has correct window' );

flush_tickit;

is_display( [ [TEXT("Widget 0"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(2),
               TEXT("Widget 2")] ],
            'Display initially' );

$widget->set_child_opts( 1, expand => 1 );

flush_tickit;

is_display( [ [TEXT("Widget 0"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(54),
               TEXT("Widget 2")] ],
            'Display after expand change' );

$statics[0]->set_text( "A longer piece of text for the static" );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(25),
               TEXT("Widget 2")] ],
            'Display after static text change' );

resize_term( 30, 100 );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(43),
               BLANK(2),
               TEXT("Widget 2")] ],
            'Display after resize' );

$widget->add( Tickit::Widget::Static->new( text => "New Widget" ) );

is( scalar $widget->children, 4, '$widget now has 4 children after new widget' );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(31),
               BLANK(2),
               TEXT("Widget 2"),
               BLANK(2),
               TEXT("New Widget")] ],
            'Display after new widget' );

$widget->set_child_opts( 2, force_size => 15 );

flush_tickit;

is_display( [ [TEXT("A longer piece of text for the static"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(24),
               BLANK(2),
               TEXT("Widget 2"),
               BLANK(7),
               BLANK(2),
               TEXT("New Widget")] ],
            'Display after force_size' );

resize_term( 30, 60 );
$term->clear;

flush_tickit;

is_display( [ [TEXT("A longer piece of text for t"),
               BLANK(2),
               TEXT("Widget"),
               BLANK(2),
               TEXT("Widget 2"),
               BLANK(2),
               BLANK(4),
               TEXT("New Widg")] ],
            'Display after resize too small' );

$widget->set_child( 0, my $initial = Tickit::Widget::Static->new( text => "A new Static" ) );

flush_tickit;

is_display( [ [TEXT("A new Static"),
               BLANK(2),
               TEXT("Widget 1"),
               BLANK(11),
               TEXT("Widget 2"),
               BLANK(2),
               BLANK(7),
               TEXT("New Widget")] ],
            'Display after set_child' );

$initial->set_text( "" );

is( $initial->requested_cols, 0, 'Initial static requests no columns' );

flush_tickit;

ok( !$initial->window, 'Initial actually has no window' );

is_display( [ [BLANK(2),
               TEXT("Widget 1"),
               BLANK(23),
               TEXT("Widget 2"),
               BLANK(2),
               BLANK(7),
               TEXT("New Widget")] ],
            'Display after set_child' );

$widget->set_style( line_style => Tickit::RenderBuffer::LINE_SINGLE );

flush_tickit;

is_display( [ [BLANK(2),
               TEXT("Widget 1"),
               BLANK(21),
               TEXT("│ "),
               TEXT("Widget 2"),
               BLANK(7),
               TEXT("│ "),
               TEXT("New Widget")],
               ( [ BLANK(2+8+21), TEXT("│ "), BLANK(8+7), TEXT("│ "), ] ) x 29
            ],
            'Display after set_style line_style' );

# add with options
{
   my $child = Tickit::Widget::Static->new( text => "" );

   $widget->add_children( { child => $child, force_size => 20 } );

   is( { $widget->child_opts( $child ) },
       { expand => 0, force_size => 20 },
       '->add_children accepts hashes with extra opts' );
}

$widget->set_window( undef );

ok( !defined $statics[0]->window, '$static has no window after ->set_window undef' );

done_testing;
