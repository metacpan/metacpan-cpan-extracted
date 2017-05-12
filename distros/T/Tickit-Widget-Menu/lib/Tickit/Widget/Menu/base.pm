#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2014 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu::base;

use strict;
use warnings;
use feature qw( switch );

use base qw( Tickit::Widget Tickit::Widget::Menu::itembase );

our $VERSION = '0.11';

use Carp;

use Tickit::Utils qw( textwidth );

use constant separator => [];

sub new
{
   my $class = shift;
   my %args = @_;

   foreach my $method (qw( pos2item on_mouse_item redraw_item popup_item activated )) {
      $class->can( $method ) or 
         croak "$class cannot ->$method - do you subclass and implement it?";
   }
   my $self = $class->SUPER::new( %args );
   $self->_init_itembase( %args );

   $self->{items} = [];
   $self->{itemwidths} = [];

   $self->{active_idx} = undef; # index of keyboard-selected highlight

   if( $args{items} ) {
      $self->push_item( $_ ) for @{ $args{items} };
   }

   return $self;
}

sub items
{
   my $self = shift;
   return @{ $self->{items} };
}

sub _itemwidth
{
   my $self = shift;
   my ( $idx ) = @_;
   return $self->{itemwidths}[$idx];
}

sub push_item
{
   my $self = shift;
   my ( $item ) = @_;

   push @{ $self->{items} }, $item;
   push @{ $self->{itemwidths} }, $item == separator ? 0 : textwidth $item->name;
}

sub highlight_item
{
   my $self = shift;
   my ( $idx ) = @_;

   return if defined $self->{active_idx} and $idx == $self->{active_idx};

   my $have_window = defined $self->window;

   if( defined( my $old_idx = $self->{active_idx} ) ) {
      undef $self->{active_idx};
      my $old_item = $self->{items}[$old_idx];
      if( $old_item->isa( "Tickit::Widget::Menu" ) ) {
         $old_item->dismiss;
      }
      $self->redraw_item( $old_idx ) if $have_window;
   }

   $self->{active_idx} = $idx;
   $self->redraw_item( $idx ) if $have_window;
}

sub expand_item
{
   my $self = shift;
   my ( $idx ) = @_;

   $self->highlight_item( $idx );

   my $item = $self->{items}[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->popup_item( $idx );
      $item->set_supermenu( $self );
   }
   # else don't bother expanding non-menus
}

sub activate_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $item = $self->{items}[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->expand_item( $idx );
   }
   else {
      $self->activated;
      $item->activate;
   }
}

sub set_on_activated
{
   my $self = shift;
   ( $self->{on_activated} ) = @_;
}

sub dismiss
{
   my $self = shift;

   if( defined $self->{active_idx} ) {
      my $item = $self->{items}[$self->{active_idx}];
      $item->dismiss if $item->isa( "Tickit::Widget::Menu" );
   }

   undef $self->{active_idx};
}

sub key_highlight_next
{
   my $self = shift;

   my $items = $self->{items};
   my $idx = $self->{active_idx};

   if( defined $idx ) {
      $idx++, $idx %= @$items;
   }
   else {
      $idx = 0;
   }

   $idx++, $idx %= @$items while $items->[$idx] == separator;

   $self->highlight_item( $idx );

   return 1;
}

sub key_highlight_prev
{
   my $self = shift;

   my $items = $self->{items};
   my $idx = $self->{active_idx};

   if( defined $idx ) {
      $idx--, $idx %= @$items;
   }
   else {
      $idx = $#$items;
   }

   $idx--, $idx %= @$items while $items->[$idx] == separator;

   $self->highlight_item( $idx );

   return 1;
}

sub key_dismiss
{
   my $self = shift;

   $self->dismiss;

   return 1;
}

sub key_activate
{
   my $self = shift;

   if( defined( my $idx = $self->{active_idx} ) ) {
      $self->activate_item( $idx );
   }

   return 1;
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   my $line = $args->line;
   my $col  = $args->col;

   if( $line < 0 or $line >= $self->window->lines or
       $col  < 0 or $col  >= $self->window->cols ) {
      $self->dismiss, return 0 if $args->type eq "press";
      return 0;
   }

   my ( $item, $item_idx, $item_col ) = $self->pos2item( $line, $col );
   $item or return 1;

   $self->on_mouse_item( $args, $item, $item_idx, $item_col );
}

0x55AA;
