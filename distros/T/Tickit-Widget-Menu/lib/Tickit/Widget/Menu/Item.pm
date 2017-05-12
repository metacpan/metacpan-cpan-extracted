#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu::Item;

use strict;
use warnings;
use base qw( Tickit::Widget::Menu::itembase );

our $VERSION = '0.11';

use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::MenuItem> - an item to display in a C<Tickit::Widget::Menu>

=head1 DESCRIPTION

Objects in this class are displayed in menus. Each item has a name and a
callback to invoke when the menu option is clicked on.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $item = Tickit::Widget::Menu::Item->new( %args )

Constructs a new C<Tickit::Widget::Menu::Item> object.

Takes the following named arguments:

=over 8

=item name => STRING

Gives the name of the menu item.

=item on_activate => CODE

Callback to invoke when the menu item is clicked on.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {
      on_activate => $args{on_activate},
   }, $class;
   $self->_init_itembase( %args );

   return $self;
}

sub activate
{
   my $self = shift;

   $self->{on_activate}->( $self ) if $self->{on_activate};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
