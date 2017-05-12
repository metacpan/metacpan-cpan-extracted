#!/usr/bin/perl

package ClickerWidget;
use base 'Tickit::Widget';

use strict;
use warnings;

use Tickit;

# In a real Widget this would be stored in an attribute of $self
my @points;

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->eraserect( $rect );
   foreach my $point ( @points ) {
      $rb->text_at( $point->[0], $point->[1], "X" );
   }
}

sub on_mouse
{
   my $self = shift;
   my ( $ev, $button, $line, $col ) = @_;

   return unless $ev eq "press" and $button == 1;

   push @points, [ $line, $col ];
   shift @points while @points > 10;
   $self->redraw;
}

Tickit->new( root => ClickerWidget->new )->run;
