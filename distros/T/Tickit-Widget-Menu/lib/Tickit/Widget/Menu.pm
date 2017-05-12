#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2017 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu;

use strict;
use warnings;
use feature qw( switch );

use Tickit::Window 0.49; # hierarchy changes are asynchronous

our $VERSION = '0.11';

# Much of this code actually lives in a class called T:W:Menu::base, which is
# the base class used by T:W:Menu and T:W:MenuBar
use base qw( Tickit::Widget::Menu::base );
use Tickit::Widget::Menu::Item;
use Tickit::Style;

use Tickit::RenderBuffer qw( LINE_SINGLE );
use List::Util qw( max min );

# Re-import the constant for compiletime use
use constant separator => __PACKAGE__->separator;

=head1 NAME

C<Tickit::Widget::Menu> - display a menu of choices

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Menu;

 my $tickit = Tickit->new;

 my $menu = Tickit::Widget::Menu->new(
    items => [
       Tickit::Widget::Menu::Item->new(
          name => "Exit",
          on_activate => sub { $tickit->stop }
       ),
    ],
 );

 $menu->popup( $tickit->rootwin, 5, 5 );

 $tickit->run;

=head1 DESCRIPTION

This widget class acts as a display container for a list of items representing
individual choices. It can be displayed as a floating window using the
C<popup> method, or attached to a L<Tickit::Widget::MenuBar> or as a child
menu within another C<Tickit::Widget::Menu>.

This widget is intended to be displayed transiently, either as a pop-up menu
over some other widget, or as a child menu of another menu or an instance of
a menu bar. Specifically, such objects should not be directly added to
container widgets.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item highlight => PEN

The pen used to highlight the active menu selection

=back

The following style actions are used:

=over 4

=item highlight_next (<Down>)

=item highlight_prev (<Up>)

Highlight the next or previous item

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
   "<Down>"   => "highlight_next",
   "<Up>"     => "highlight_prev",
   "<Enter>"  => "activate",
   "<Escape>" => "dismiss";

use constant KEYPRESSES_FROM_STYLE => 1;
use constant WIDGET_PEN_FROM_STYLE => 1;

# These methods come from T:W:Menu::base but better to document them here so
# the reader can find them

=head1 CONSTRUCTOR

=head2 $menu = Tickit::Widget::Menu->new( %args )

Constructs a new C<Tickit::Widget::Menu> object.

Takes the following named arguments:

=over 8

=item name => STRING

Optional. If present, gives the name of the menu item for a submenu. Not used
in a top-level menu.

=item items => ARRAY

Optional. If present, contains a list of C<Tickit::Widget::Menu::Item> or
C<Tickit::Widget::Menu> objects to add to the menu. Equivalent to passing each
to the C<push_item> method after construction.

=back

=head2 $separator = Tickit::Window::Menu->separator

Returns a special menu item which draws a separation line between its
neighbours.

=cut

=head1 METHODS

=cut

sub lines
{
   my $self = shift;
   return 2 + $self->items;
}

sub cols
{
   my $self = shift;
   return 4 + max( map { $self->_itemwidth( $_ ) } 0 .. $self->items-1 );
}

=head2 $name = $menu->name

Returns the string name for the menu.

=head2 @items = $menu->items

Returns the list of items currently stored.

=head2 $menu->push_item( $item )

Adds another item.

Each item may either be created using L<Tickit::Window::Menu::Item>'s
constructor, another C<Tickit::Widget::Menu> item itself (to create a
submenu), or the special separator value.

=cut

=head2 $menu->highlight_item( $idx )

Gives the selection highlight to the item at the given index. This may be
called before the menu is actually displayed in order to pre-select the
highlight initially.

=cut

=head2 $menu->popup( $win, $line, $col )

Makes the menu appear at the given position relative to the given window. Note
that as C<< $win->make_popup >> is called, the menu is always displayed in a
popup window, floating over the root window. Passed window is used simply as
the origin for the given line and column position.

=cut

sub popup
{
   my $self = shift;
   my ( $parentwin, $line, $col ) = @_;

   my $win = $parentwin->make_popup( $line, $col, $self->lines, $self->cols );
   $self->set_window( $win );
   $win->show;
}

=head2 $menu->dismiss

Hides a menu previously displayed using C<popup>.

=cut

sub set_supermenu
{
   my $self = shift;
   ( $self->{supermenu} ) = @_;
}

sub pos2item
{
   my $self = shift;
   my ( $line, $col ) = @_;

   $line > 0 or return ();
   $line--;

   $col > 1 or return ();
   $col < $self->cols - 1 or return ();
   $col -= 2;

   my @items = $self->items;
   $line < @items or return ();

   return ( $items[$line], $line, $col );
}

sub redraw_item
{
   my $self = shift;
   my ( $idx ) = @_;
   $self->window->expose( Tickit::Rect->new(
      top => $idx + 1, lines => 1,
      left => 0, cols => $self->window->cols,
   ) );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $lines = $self->window->lines;
   my $cols  = $self->window->cols;

   $rb->hline_at( 0, 0, $cols-1, LINE_SINGLE );
   $rb->hline_at( $lines-1, 0, $cols-1, LINE_SINGLE );
   $rb->vline_at( 0, $lines-1, 0, LINE_SINGLE );
   $rb->vline_at( 0, $lines-1, $cols-1, LINE_SINGLE );

   foreach my $line ( $rect->linerange( 1, $lines-2 ) ) {
      my $idx = $line - 1;
      my $item = $self->{items}[$idx];

      if( $item == separator ) {
         $rb->hline_at( $line, 0, $cols-1, LINE_SINGLE );
      }
      else {
         $rb->erase_at( $line, 1, 1 );
         if( $item->isa( "Tickit::Widget::Menu" ) ) {
            $rb->text_at( $line, $cols-2, ">" );
         }
         else {
            $rb->erase_at( $line, $cols-2, 1 );
         }

         my $pen = defined $self->{active_idx} && $idx == $self->{active_idx}
                     ? $self->get_style_pen( "highlight" ) : undef;

         $rb->savepen;
         $rb->setpen( $pen ) if $pen;

         $rb->erase_at( $line, 2, $cols-4 );
         $rb->goto( $line, 2 );
         $item->render_label( $rb, $cols-4, $self );

         $rb->restore;
      }
   }
}

sub popup_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $item = $self->{items}[$idx];

   $item->popup( $self->window, $idx + 1, $self->window->cols );
}

sub activated
{
   my $self = shift;
   $self->dismiss;

   $self->{supermenu}->activated if $self->{supermenu};
   $self->{on_activated}->() if $self->{on_activated};
}

sub dismiss
{
   my $self = shift;

   if( $self->window ) {
      $self->window->hide;
      $self->set_window( undef );
   }

   $self->SUPER::dismiss;
}

sub on_key
{
   my $self = shift;

   # Eat keys if there's no supermenu to pass them to
   return !$self->{supermenu};
}

sub on_mouse_item
{
   my $self = shift;
   my ( $args, $item, $item_idx, $item_col ) = @_;

   # Separators do not react to mouse
   return 1 if $item == separator;

   my $event = $args->type;
   if( $event eq "press" || $event eq "drag" and $args->button == 1 ) {
      $self->expand_item( $item_idx );
   }
   elsif( $event eq "release" ) {
      if( defined $self->{active_idx} and $self->{active_idx} == $item_idx ) {
         $self->activate_item( $item_idx );
      }
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
