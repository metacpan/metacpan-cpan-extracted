#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Tickit::Widget::MenuBar 0.14;
class Tickit::Widget::MenuBar
   :isa(Tickit::Widget::Menu::base);

use Tickit::Style;

use Carp;

use Tickit::RenderBuffer qw( LINE_SINGLE );
use List::Util qw( sum max );

# Re-import the constant for compiletime use
use constant separator => __PACKAGE__->separator;

=head1 NAME

C<Tickit::Widget::MenuBar> - display a menu horizontally

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Menu;
   use Tickit::Widget::Menu::Item;
   use Tickit::Widget::MenuBar;
   use Tickit::Widget::VBox;

   my $tickit = Tickit->new;

   my $vbox = Tickit::Widget::VBox->new;
   $tickit->set_root_widget( $vbox );

   $vbox->add( Tickit::Widget::MenuBar->new(
      items => [
         ...
      ]
   );

   $vbox->add( ... );

   $tickit->run;

=head1 DESCRIPTION

This widget class acts as a container for menu items similar to
L<Tickit::Widget::Menu> but displays them horizonally in a single line. This
widget is intended to display long-term, such as in the top line of the root
window, rather than being used only transiently as a pop-up menu.

This widget should be used similarly to L<Tickit::Widget::Menu>, except that
its name is never useful, and it should be added to a container widget, such
as L<Tickit::Widget::VBox>, for longterm display. It does not have a C<popup>
or C<dismiss> method.

A single separator object can be added as an item, causing all the items after
it to be right-justified.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item highlight => PEN

The pen used to highlight the active menu selection

=back

The following style actions are used:

=over 4

=item highlight_next (<Right>)

=item highlight_prev (<Left>)

Highlight the next or previous item

=item highlight_first (<F10>)

Highlight the first menu item

=item activate (<Enter>)

Activate the highlighted item

=item dismiss (<Escape>)

Dismiss the menu

=back

=cut

style_definition base =>
   rv => 1,
   highlight_rv => 0,
   highlight_bg => "green",
   "<Right>" => "highlight_next",
   "<Left>"  => "highlight_prev",
   "<F10>"   => "highlight_first",
   "<Enter>"  => "activate",
   "<Escape>" => "dismiss";

use constant KEYPRESSES_FROM_STYLE => 1;
use constant WIDGET_PEN_FROM_STYLE => 1;

has @_itempos;

method lines ()
{
   return 1;
}

method cols ()
{
   return sum( map { $self->_itemwidth( $_ ) } 0 .. $self->items-1 ) + 2 * ( $self->items - 1 );
}

method push_item ( $item )
{
   if( $item == separator and grep { $_ == separator } $self->items ) {
      croak "Cannot have more than one separator in a MenuBar";
   }

   $self->SUPER::push_item( $item );
}

method reshape ()
{
   @_itempos = ();

   my @items = $self->items;
   my $col = 0;
   my $separator_at;
   foreach my $idx ( 0 .. $#items ) {
      $separator_at = $idx, next if $items[$idx] == separator;

      $_itempos[$idx] = [ $col, undef ];
      $col += $self->_itemwidth( $idx );
      $_itempos[$idx][1] = $col;
      $col += 2;
   }

   if( defined $separator_at ) {
      $col -= 2; # undo
      my $spare = $self->window->cols - $col;

      $_itempos[$_][0] += $spare, $_itempos[$_][1] += $spare for $separator_at+1 .. $#items;
   }
}

method pos2item ( $line, $col )
{
   $line == 0 or return ();

   my @items = $self->items;

   foreach my $idx ( 0 .. $#items ) {
      next if !defined $_itempos[$idx]; # separator
      last if     $col < $_itempos[$idx][0];
      next unless $col < $_itempos[$idx][1];

      $col -= $_itempos[$idx][0];

      return () if $col < 0;
      return ( $items[$idx], $idx, $col );
   }

   return ();
}

method redraw_item ( $idx )
{
   $self->window->expose( Tickit::Rect->new(
      top => 0, lines => 1,
      left  => $_itempos[$idx][0],
      right => $_itempos[$idx][1],
   ) );
}

method render_to_rb ( $rb, $rect )
{
   if( $rect->top == 0 ) {
      $rb->goto( 0, 0 );

      my @items = $self->items;
      foreach my $idx ( 0 .. $#items ) {
         my $item = $items[$idx];
         next if $item == separator;

         my ( $left, $right ) = @{ $_itempos[$idx] };
         last if $left > $rect->right;
         next if $right < $rect->left;

         $rb->erase_to( $left );

         my $pen = defined $self->_active_idx && $idx == $self->_active_idx
                     ? $self->get_style_pen( "highlight" ) : undef;

         $rb->savepen;
         $rb->setpen( $pen );

         $item->render_label( $rb, $right - $left, $self );

         $rb->restore;
      }

      $rb->erase_to( $rect->right );
   }

   foreach my $line ( $rect->linerange( 1, undef ) ) {
      $rb->erase_at( $line, $rect->left, $rect->cols );
   }
}

method popup_item ( $idx )
{
   my $item = $self->item( $idx );

   my $col = $_itempos[$idx][0];

   my $rightmost = $self->window->cols - $item->cols;
   $col = $rightmost if $col > $rightmost;

   $item->popup( $self->window, 1, $col );
}

method activated ()
{
   $self->dismiss;
}

method dismiss ()
{
   $self->SUPER::dismiss;

   # Still have a window after ->dismiss
   $self->redraw;
}

method on_key ( $ )
{
   # Always eat all the keys as there's never anything higher to pass them to
   return 1;
}

# MenuBar always expands on highlight
method key_highlight_next ( $ )
{
   $self->SUPER::key_highlight_next( @_ );
   $self->expand_item( $self->_active_idx );
}

method key_highlight_prev ( $ )
{
   $self->SUPER::key_highlight_prev( @_ );
   $self->expand_item( $self->_active_idx );
}

method key_highlight_first ( $ )
{
   defined $self->_active_idx or $self->expand_item( 0 );
   return 1;
}

method on_mouse_item ( $args, $item, $item_idx, $item_col )
{
   # We only ever care about button 1
   return unless $args->button == 1;

   my $event = $args->type;
   if( $event eq "press" ) {
      # A second click on an active item deactivates
      if( defined $self->_active_idx and $item_idx == $self->_active_idx ) {
         $self->dismiss;
      }
      else {
         $self->expand_item( $item_idx );
      }
   }
   elsif( $event eq "drag" ) {
      $self->expand_item( $item_idx );
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
