#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::FloatBox;
use Tickit::Widget::Static;

my $win = mk_window;

my ( $child_lines, $child_cols );

my $widget = Tickit::Widget::FloatBox->new
   ->set_base_child( TestWidget->new );

$widget->set_window( $win );
flush_tickit;

is_display( [ ( [TEXT("C" x 80)] ) x 25 ],
   'Display initially' );

my $float;

$float = $widget->add_float(
   child => Tickit::Widget::Static->new( text => "Hello, world!" ),

   top => 0, left => 0,
);
flush_tickit;

ok( defined $float, '$float defined' );

identical( $float->child->parent, $widget, '$float->child->parent' );

is_display( [ [TEXT("Hello, world!"), TEXT("C" x 67)],
              ( [TEXT("C" x 80)] ) x 24 ],
   'Display with single float in top-left' );

$float->move( left => undef, right => -1 );
flush_tickit;

is_display( [ [TEXT("C" x 67), TEXT("Hello, world!")],
              ( [TEXT("C" x 80)] ) x 24 ],
   'Display after moving float to top-right' );

$float->move( top => undef, bottom => -1, left => 0, right => -1 );
flush_tickit;

is_display( [ ( [TEXT("C" x 80)] ) x 24,
              [TEXT("Hello, world!")] ],
   'Display after moving float to bottom fullwidth' );

resize_term( 15, 45 );
flush_tickit;

is_display( [ ( [TEXT("C" x 45)] ) x 14,
              [TEXT("Hello, world!")] ],
   'Display after resizing terminal' );

$float->remove;
flush_tickit;

is_display( [ ( [TEXT("C" x 45)] ) x 15 ],
   'Display after $float->remove' );

done_testing;

package TestWidget;

use base qw( Tickit::Widget );
use constant WIDGET_PEN_FROM_STYLE => 1;

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   foreach my $line ( $rect->linerange ) {
      $rb->text_at( $line, $rect->left, "C" x $rb->cols );
   }
}

sub lines { $child_lines }
sub cols  { $child_cols }
