# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ValidationError;
$WebService::Braintree::ValidationError::VERSION = '1.2';
=head1 NAME

WebService::Braintree::ValidationError

=head1 PURPOSE

This class represents an error, usually from a failed validation.

This class will only be created as part of a L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

=head1 METHODS

=head2 attribute()

This is the attribute in the unsuccessful request which failed validation.

=cut

has 'attribute' => (is => 'ro');

=head2 code()

This is the validation error code returned from Braintree.

=cut

has 'code' => (is => 'ro');

=head2 message()

This is the explanatory message provided by Braintree for this error.

=cut

has 'message' => (is => 'ro');

__PACKAGE__->meta->make_immutable;

1;
__END__
