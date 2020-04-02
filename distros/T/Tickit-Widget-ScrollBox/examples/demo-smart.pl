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
)->set_child(
   Tickit::Widget::ScrollBox->new(
      style => { bg => "black" },
   )->set_child(
      ScrollableWidget->new
   )
);

Tickit->new( root => $border )->run;

use Object::Pad 0.17;
class ScrollableWidget extends Tickit::Widget;

use constant CAN_SCROLL => 1;

method lines () { 1 }
method cols  () { 1 }

has $_vextent; method vextent () { $_vextent }
has $_hextent; method hextent () { $_hextent }

method set_scrolling_extents
{
   ( $_vextent, $_hextent ) = @_;
   $_vextent->set_total( 100 ) if $_vextent;
   $_hextent->set_total(  50 ) if $_hextent;
}

method scrolled ( $downward, $rightward, $id )
{
   $self->redraw;
}

method render_to_rb ( $rb, $rect )
{
   $rb->clear;

   my $vstart = $self->vextent ? $self->vextent->start : 0;
   my $hstart = $self->hextent ? $self->hextent->start : 0;

   $rb->text_at( 1, 1, "Render with vstart=$vstart hstart=$hstart" );
}
