# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Address;
$WebService::Braintree::Address::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Address

=head1 PURPOSE

This class creates, updates, deletes, and finds addresses.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< address() >> set.

=cut

sub create {
    my($class, $params) = @_;
    $class->gateway->address->create($params);
}

=head2 find()

This takes a customer_id and an address_id and returns a L<response|WebService::Braintee::Result> with the C<< address() >> set (if found).

=cut

sub find {
    my ($class, $customer_id, $address_id) = @_;
    $class->gateway->address->find($customer_id, $address_id);
}

=head2 update()

This takes a customer_id, an address_id, and a hashref of parameters. It will
update the corresponding address (if found) and return a L<response|WebService::Braintee::Result> with the updated C<< address() >> (if found).

=cut

sub update {
    my ($class, $customer_id, $address_id, $params) = @_;
    $class->gateway->address->update($customer_id, $address_id, $params);
}

=head2 delete()

This takes a customer_id and an address_id and deletes the corresponding
address (if found). It returns a L<response|WebService::Braintee::Result>.

=cut

sub delete {
    my ($class, $customer_id, $address_id) = @_;
    $class->gateway->address->delete($customer_id, $address_id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
