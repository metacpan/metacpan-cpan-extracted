# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Dispute::TransactionDetails;
$WebService::Braintree::_::Dispute::TransactionDetails::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Dispute::TransactionDetails

=head1 PURPOSE

This class represents a transaction detail of a dispute.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 amount()

This is the amount for this dispute's transaction details.

=cut

# Coerce this to "big_decimal"
has amount => (
    is => 'ro',
);

=head2 id()

This is the ID for this dispute's transaction details.

=cut

has id => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
