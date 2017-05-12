#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::Border;

my $border = Tickit::Widget::Border->new(
   h_border => 6,
   v_border => 2,
   style => { bg => "green" },
   child => Tickit::Widget::ScrollBox->new(
      child => ScrollableWidget->new,
      style => { bg => "black" },
   ),
);

Tickit->new( root => $border )->run;

package ScrollableWidget;
use base qw( Tickit::Widget );

sub lines { 1 }
sub cols  { 1 }

use constant CAN_SCROLL => 1;

sub set_scrolling_extents
{
   my $self = shift;
   ( $self->{vextent}, $self->{hextent} ) = @_;
   $self->{vextent}->set_total( 100 ) if $self->{vextent};
   $self->{hextent}->set_total(  50 ) if $self->{hextent};
}

sub scrolled
{
   my $self = shift;
   my ( $downward, $rightward, $id ) = @_;

   $self->redraw;
}

sub vextent { shift->{vextent} }
sub hextent { shift->{hextent} }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->clear;

   my $vstart = $self->vextent ? $self->vextent->start : 0;
   my $hstart = $self->hextent ? $self->hextent->start : 0;

   $rb->text_at( 1, 1, "Render with vstart=$vstart hstart=$hstart" );
}
