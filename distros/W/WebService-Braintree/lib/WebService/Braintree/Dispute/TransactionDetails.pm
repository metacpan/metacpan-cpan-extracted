package WebService::Braintree::Dispute::TransactionDetails;
$WebService::Braintree::Dispute::TransactionDetails::VERSION = '0.93';
=head1 NAME

WebService::Braintree::Dispute::TransactionDetails

=head1 PURPOSE

This class represents a set of transaction details for a dispute.

=cut

use Moose;
extends 'WebService::Braintree::ResultObject';

=head1 CLASS METHODS

This class is B<NOT> an interface, so it does B<NOT> have any class methods.

=head1 OBJECT METHODS

NONE

=cut

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

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
