#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.73 ':experimental(init_expr)';

package Tickit::Widget::Menu::Item 0.16;
class Tickit::Widget::Menu::Item
   :strict(params)
   :does(Tickit::Widget::Menu::itembase);

use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::MenuItem> - an item to display in a C<Tickit::Widget::Menu>

=head1 DESCRIPTION

Objects in this class are displayed in menus. Each item has a name and a
callback to invoke when the menu option is clicked on.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $item = Tickit::Widget::Menu::Item->new( %args )

Constructs a new C<Tickit::Widget::Menu::Item> object.

Takes the following named arguments:

=over 8

=item name => STRING

Gives the name of the menu item.

=item on_activate => CODE

Callback to invoke when the menu item is clicked on.

=back

=cut

field $_on_activate :param = undef;

method activate ()
{
   $_on_activate->( $self ) if $_on_activate;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
