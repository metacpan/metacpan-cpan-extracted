package WebService::Braintree::Address;
$WebService::Braintree::Address::VERSION = '1.1';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Address

=head1 PURPOSE

This class creates, updates, deletes, and finds addresses.

=cut

use Moose;
extends 'WebService::Braintree::ResultObject';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns the address created.

=cut

sub create {
    my($class, $params) = @_;
    $class->gateway->address->create($params);
}

=head2 find()

This takes a customer_id and an address_id and returns the address (if it
exists).

=cut

sub find {
    my ($class, $customer_id, $address_id) = @_;
    $class->gateway->address->find($customer_id, $address_id);
}

=head2 update()

This takes a customer_id, an address_id, and a hashref of parameters. It will
update the corresponding address (if found) and returns the updated address.

=cut

sub update {
    my ($class, $customer_id, $address_id, $params) = @_;
    $class->gateway->address->update($customer_id, $address_id, $params);
}

=head2 delete()

This takes a customer_id and an address_id and deletes the corresponding
address (if found).

=cut

sub delete {
    my ($class, $customer_id, $address_id) = @_;
    $class->gateway->address->delete($customer_id, $address_id);
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 full_name()

This returns the full name of this address. This is the first_name and the
last_name concatenated with a space.

=cut

sub full_name {
    my $self = shift;
    return $self->first_name . " " . $self->last_name
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
