#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu::itembase;

use strict;
use warnings;

our $VERSION = '0.11';

sub _init_itembase
{
   my $self = shift;
   my %args = @_;

   $self->{name} = $args{name};
}

sub name
{
   my $self = shift;
   return $self->{name};
}

sub render_label
{
   my $self = shift;
   my ( $rb, $cols, $menu ) = @_;

   $rb->text( $self->name );
}

0x55AA;
