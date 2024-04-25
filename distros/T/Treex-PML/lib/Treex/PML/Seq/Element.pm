
=head2 Treex::PML::Seq::Element

This class implements an element of a 'sequence', i.e. a name-value
pair.

=over 4

=cut

package Treex::PML::Seq::Element;
use 5.008;
use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}
use Carp;

=item Treex::PML::Seq::Element->new (name, value)

Create a new sequence element.

=cut

  sub new {
    my ($class,$name, $value) = @_;
    return bless [$name,$value],$class;
  }

=item $el->name ()

Return the name of the element.

=cut

  sub name {
    $_[0]->[0];
  }


=item $el->value ()

Return the value of the element.

=cut

  sub value {
    $_[0]->[1];
  }

=item $el->set_name (name)

Set name of the element

=cut

  sub set_name {
    $_[0]->[0] = $_[1];
  }

=item $el->set_value (value)

Set value of the element

=cut

  sub set_value {
    $_[0]->[1] = $_[1];
  }

=back

=cut

1;
__END__
