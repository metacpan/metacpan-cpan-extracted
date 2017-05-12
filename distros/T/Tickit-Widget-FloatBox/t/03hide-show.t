#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::FloatBox;
use Tickit::Widget::Static;

my $win = mk_window;

my $widget = Tickit::Widget::FloatBox->new(
   base_child => TestWidget->new,
);

$widget->set_window( $win );

{
   my $float = $widget->add_float(
      child => Tickit::Widget::Static->new( text => "Hello, world!" ),
      top => 0, left => 0,
   );

   flush_tickit;

   is_display( [ [TEXT("Hello, world!"), TEXT("C" x 67)],
                 ( [TEXT("C" x 80)] ) x 24 ],
      'Display with single float' );
   ok ( $float->is_visible, '$float->is_visible true initially' );

   $float->hide;
   flush_tickit;

   is_display( [ ( [TEXT("C" x 80)] ) x 25 ],
      'Display after hiding float' );
   ok ( !$float->is_visible, '$float->is_visible false after hiding float' );

   $float->show;
   flush_tickit;

   is_display( [ [TEXT("Hello, world!"), TEXT("C" x 67)],
                 ( [TEXT("C" x 80)] ) x 24 ],
      'Display after showing float again' );

   $float->remove;
}

# initially-hidden
{
   my $float = $widget->add_float(
      child => Tickit::Widget::Static->new( text => "Hello, world!" ),
      top => 0, right => -1,
      hidden => 1,
   );

   flush_tickit;

   is_display( [ ( [TEXT("C" x 80)] ) x 25 ],
      'Display after creating initially-hidden float' );

   $float->show;
   flush_tickit;

   is_display( [ [TEXT("C" x 67), TEXT("Hello, world!")],
                 ( [TEXT("C" x 80)] ) x 24 ],
      'Display after showing float again' );

   $float->remove;
}

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

sub lines { 1 }
sub cols  { 1 }
