package VANAMBURG::SEMPROG::InferenceRule;

=head1 VANAMBURG::SEMPROG::InferenceRule

Used as an abstract base class to require two methods
in InferenceRule implementations.

=over 4

=item *

getqueries

=item *

maketriples

=back

=cut

use Moose::Role;

requires qw/getqueries maketriples/;

1;

