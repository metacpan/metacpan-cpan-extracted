#!/usr/bin/perl

package ClickAndDragWidget;
use base 'Tickit::Widget';

use v5.14;
use warnings;

use Tickit;

use Tickit::Widget::Placegrid;

use List::Util qw( min max );

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   shift;
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );
}

# In a real Widget these would be stored in an attribute of $self
my @start;
my $dragframe;

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   if( $args->type eq "release" ) {
      $dragframe->window->close if $dragframe;
      undef $dragframe;
      return;
   }

   return unless $args->button == 1;

   if( $args->type eq "press" ) {
      @start = ( $args->line, $args->col );
      return;
   }

   my $top   = min( $start[0], $args->line );
   my $left  = min( $start[1], $args->col );
   my $lines = max( $start[0], $args->line ) - $top + 1;
   my $cols  = max( $start[1], $args->col ) - $left + 1;

   return if( $lines == 0 or $cols == 0 );

   $self->window->expose;

   if( $dragframe ) {
      $dragframe->window->change_geometry( $top, $left, $lines, $cols );
   }
   else {
      $dragframe = Tickit::Widget::Placegrid->new;

      $dragframe->set_window(
         $self->window->make_sub( $top, $left, $lines, $cols )
      );
   }
}

Tickit->new( root => ClickAndDragWidget->new )->run;
