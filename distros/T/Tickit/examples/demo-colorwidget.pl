#!/usr/bin/perl

package ColourWidget;
use base 'Tickit::Widget';

use strict;
use warnings;

use Tickit;

my $text = "Press 0 to 7 to change the colour of this text";

sub lines { 1 }
sub cols  { length $text }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->eraserect( $rect );

   $rb->text_at( ( $win->lines - $self->lines ) / 2, ( $win->cols - $self->cols ) / 2, $text );

   $win->focus( 0, 0 );
}

sub on_key
{
   my $self = shift;
   my ( $args ) = @_;

   if( $args->type eq "text" and $args->str =~ m/[0-7]/ ) {
      $self->set_style( fg => $args->str );
      $self->redraw;
      return 1;
   }

   return 0;
}

Tickit->new( root => ColourWidget->new )->run;
