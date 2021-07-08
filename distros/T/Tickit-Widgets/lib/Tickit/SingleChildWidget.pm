#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.27;

package Tickit::SingleChildWidget 0.54;
class Tickit::SingleChildWidget
   extends Tickit::ContainerWidget
   implements Tickit::WidgetRole::SingleChildContainer;

use Carp;

=head1 NAME

C<Tickit::SingleChildWidget> - abstract base class for widgets that contain a
single other widget

=head1 SYNOPSIS

 TODO

=head1 DESCRIPTION

This subclass of L<Tickit::ContainerWidget> acts as an abstract base class for
widgets that contain exactly one other widget. It enforces that only one child
widget may be contained at any one time, and provides a convenient accessor to
obtain it.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $widget = Tickit::SingleChildWidget->new( %args )

Constructs a new C<Tickit::SingleChildWidget> object.

=cut

BUILD
{
   my %args = @_;

   if( exists $args{child} ) {
      croak "The 'child' constructor argument to ${\ref $self} is no longer recognised; use ->set_child instead";
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
