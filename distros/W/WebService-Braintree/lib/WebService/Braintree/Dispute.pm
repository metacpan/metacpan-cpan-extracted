package WebService::Braintree::Dispute;
$WebService::Braintree::Dispute::VERSION = '0.92';
=head1 NAME

WebService::Braintree::Dispute

=head1 PURPOSE

This class represents a dispute.

=cut

use WebService::Braintree::Dispute::TransactionDetails;
use WebService::Braintree::Dispute::Status;
use WebService::Braintree::Dispute::Reason;

use Moose;
extends 'WebService::Braintree::ResultObject';

=head1 CLASS METHODS

This class is B<NOT> an interface, so it does B<NOT> have any class methods.

=head1 OBJECT METHODS

=cut

sub BUILD {
    my ($self, $attributes) = @_;

    $self->transaction_details(WebService::Braintree::Dispute::TransactionDetails->new($attributes->{transaction})) if ref($attributes->{transaction}) eq 'HASH';
    delete($attributes->{transaction});
    $self->set_attributes_from_hash($self, $attributes);
}

=pod

In addition to the methods provided by B<TODO>, this class provides the
following methods:

=head2 transaction_details()

This returns the transaction details associated with this dispute (if any).
This will be an object of type
L<WebService::Braintree::Dispute::TransactionDetails/>.

=cut

has transaction_details => (is => 'rw');

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 TODO

=over 4

=item Need to document the keys and values that are returned

=item Need to document the required and optional input parameters

=item Need to document the possible errors/exceptions

=back

=cut
