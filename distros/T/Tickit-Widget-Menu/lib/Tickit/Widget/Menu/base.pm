#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.70 ':experimental(adjust_params)';

package Tickit::Widget::Menu::base 0.16;
class Tickit::Widget::Menu::base
   :strict(params)
   :isa(Tickit::Widget)
   :does(Tickit::Widget::Menu::itembase);

use Carp;

use Tickit::Utils qw( textwidth );

use constant separator => [];

#   foreach my $method (qw( pos2item on_mouse_item redraw_item popup_item activated )) {
#      $class->can( $method ) or 
#         croak "$class cannot ->$method - do you subclass and implement it?";
#   }

field @_items;
field @_itemwidths;

field $_active_idx; # index of keyboard-selected highlight

ADJUST :params (
   :$items = undef
) {
   if( $items ) {
      $self->push_item( $_ ) for $items->@*;
   }
}

method _active_idx ()
{
   return $_active_idx;
}

method items ()
{
   return @_items;
}

method item ( $idx )
{
   return $_items[$idx];
}

method _itemwidth ( $idx )
{
   return $_itemwidths[$idx];
}

method push_item ( $item )
{
   push @_items, $item;
   push @_itemwidths, $item == separator ? 0 : textwidth $item->name;
}

method highlight_item ( $idx )
{
   return if defined $_active_idx and $idx == $_active_idx;

   my $have_window = defined $self->window;

   if( defined( my $old_idx = $_active_idx ) ) {
      undef $_active_idx;
      my $old_item = $_items[$old_idx];
      if( $old_item->isa( "Tickit::Widget::Menu" ) ) {
         $old_item->dismiss;
      }
      $self->redraw_item( $old_idx ) if $have_window;
   }

   $_active_idx = $idx;
   $self->redraw_item( $idx ) if $have_window;
}

method expand_item ( $idx )
{
   $self->highlight_item( $idx );

   my $item = $_items[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->popup_item( $idx );
      $item->set_supermenu( $self );
   }
   # else don't bother expanding non-menus
}

method activate_item ( $idx )
{
   my $item = $_items[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->expand_item( $idx );
   }
   else {
      $self->activated;
      $item->activate;
   }
}

method dismiss ()
{
   if( defined $_active_idx ) {
      my $item = $_items[$_active_idx];
      $item->dismiss if $item->isa( "Tickit::Widget::Menu" );
   }

   undef $_active_idx;
}

method key_highlight_next ( $ )
{
   my $idx = $_active_idx;

   if( defined $idx ) {
      $idx++, $idx %= @_items;
   }
   else {
      $idx = 0;
   }

   $idx++, $idx %= @_items while $_items[$idx] == separator;

   $self->highlight_item( $idx );

   return 1;
}

method key_highlight_prev ( $ )
{
   my $idx = $_active_idx;

   if( defined $idx ) {
      $idx--, $idx %= @_items;
   }
   else {
      $idx = $#_items;
   }

   $idx--, $idx %= @_items while $_items[$idx] == separator;

   $self->highlight_item( $idx );

   return 1;
}

method key_dismiss ( $ )
{
   $self->dismiss;

   return 1;
}

method key_activate ( $ )
{
   if( defined( my $idx = $_active_idx ) ) {
      $self->activate_item( $idx );
   }

   return 1;
}

method on_mouse ( $args )
{
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
