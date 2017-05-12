#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::FloatBox;

my $win = mk_window;

my ( $child_lines, $child_cols );
my $child_render_rect;

my $widget = Tickit::Widget::FloatBox->new(
   base_child => TestWidget->new,
);

ok( defined $widget, 'defined $widget' );

is( scalar $widget->children, 1, 'scalar $widget->children' );
identical( ( $widget->children )[0], $widget->base_child, '$widget->children[0]' );
identical( ( $widget->children )[0]->parent, $widget, '$widget->children[0]->parent' );

$child_lines = 3; $child_cols = 10;

is( $widget->lines,  3, '$widget->lines with no bounds' );
is( $widget->cols,  10, '$widget->cols with no bounds' );

$widget->set_window( $win );
flush_tickit;

is( $child_render_rect, Tickit::Rect->new( top => 0, left => 0, lines => 25, cols => 80 ),
   'child render rect' );

resize_term( 30, 100 );
flush_tickit;

is( $child_render_rect, Tickit::Rect->new( top => 0, left => 0, lines => 30, cols => 100 ),
   'child render rect after term resize' );

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub render_to_rb
{
   my $self = shift;
   $child_render_rect = $self->window->rect;
}

sub lines { $child_lines }
sub cols  { $child_cols }
