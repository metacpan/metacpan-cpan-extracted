#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2020 -- leonerd@leonerd.org.uk

package Tickit::WidgetRole::Alignable;

use strict;
use warnings;
use base qw( Tickit::WidgetRole );

our $VERSION = '0.51';

use Carp;

use Tickit::Utils qw( align );

=head1 NAME

C<Tickit::WidgetRole::Alignable> - implement widgets with adjustable alignment

=head1 DESCRIPTION

Mixing this parametric role into a L<Tickit::Widget> subclass adds behaviour
to implement alignment of content within a possibly-larger space.

=cut

=head1 METHODS

The following methods are provided parametrically on the caller package when
the module is imported by

   use Tickit::WidgetRole::Alignable
      name    => NAME,
      style   => STYLE,
      reshape => RESHAPE;

The parameters are

=over 4

=item name => STRING

Optional. The name to use for C<NAME> in the following generated methods.
Defaults to C<'align'> if not provided.

=item dir => "h" or "v"

Optional. The direction, horizontal or vertical, that the alignment
represents. Used to parse symbolic names into fractions. Defaults to C<'h'> if
not provided.

=item reshape => BOOL

Optional. If true, the widget will be reshaped after the value has been set by
calling the C<reshape> method. If false or absent then it will just be redrawn
by calling C<redraw>.

=back

=cut

my %symbolics = (
   h => { left => 0.0, centre => 0.5, right  => 1.0 },
   v => { top  => 0.0, middle => 0.5, bottom => 1.0 },
);

sub export_subs_for
{
   my $class = shift;
   shift;
   my %args = @_;

   my $name = $args{name} || "align";
   my $dir  = $args{dir}  || "h";

   my $post_set_method = $args{reshape} ? "reshape" : "redraw";

   my $symbolics = $symbolics{$dir} or croak "Unrecognised dir - $dir";

   return {
      "$name" => sub {
         my $self = shift;
         return $self->{$name};
      },
      "set_$name" => sub {
         my $self = shift;
         my ( $align ) = @_;

         # Convert symbolics
         $align = $symbolics->{$align} if exists $symbolics->{$align};

         $self->{$name} = $align;

         $self->$post_set_method;
      },

      "_${name}_allocation" => sub {
         my $self = shift;
         my ( $value, $total ) = @_;

         return align( $value, $total, $self->$name );
      },
   };
}

=head2 I<NAME>

   $align = $widget->NAME

Return the current alignment value

=cut

=head2 set_I<NAME>

   $widget->set_NAME( $value )

Set the new alignment value

Gives a value in the range from C<0.0> to C<1.0> to align the content display
within the window.

For vertical direction alignments, the symbolic values C<top>, C<middle> and
C<bottom> can be supplied instead of C<0.0>, C<0.5> and C<1.0> respectively.

For horizontal direction alignments, the symbolic values C<left>, C<centre>
and C<right> can be supplied instead of C<0.0>, C<0.5> and C<1.0>
respectively.

=head2 _I<NAME>_allocation

   ( $before, $alloc, $after ) = $widget->_NAME_allocation( $value, $total )

Returns a list of three integers created by aligning the C<$value> to the
given alignment position within the C<$total>. See also C<align> in
L<Tickit::Utils>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
