package WebService::Braintree::Customer;
$WebService::Braintree::Customer::VERSION = '0.93';
=head1 NAME

WebService::Braintree::Customer

=head1 PURPOSE

This class creates, updates, deletes, and finds customers.

=cut

use Moose;
extends 'WebService::Braintree::ResultObject';

=head2 create()

This takes a hashref of parameters and returns the customer created.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->customer->create($params);
}

=head2 find()

This takes a customer_id returns the customer (if it exists).

=cut

sub find {
    my($class, $id) = @_;
    $class->gateway->customer->find($id);
}

=head2 update()

This takes a customer_id and a hashref of parameters. It will update the
corresponding customer (if found) and returns the updated customer.

=cut

sub update {
    my ($class, $id, $params) = @_;
    $class->gateway->customer->update($id, $params);
}

=head2 delete()

This takes a customer_id and deletes the corresponding customer (if found).

=cut

sub delete {
    my ($class, $id) = @_;
    $class->gateway->customer->delete($id);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
customer object.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->customer->search($block);
}

=head2 all()

This returns all the customers.

=cut

sub all {
    my ($class) = @_;
    $class->gateway->customer->all;
}

sub gateway {
    return WebService::Braintree->configuration->gateway;
}

sub BUILD {
    my ($self, $attributes) = @_;
    my $sub_objects = {
        addresses => "WebService::Braintree::Address",
        credit_cards => "WebService::Braintree::CreditCard",
        paypal_accounts => "WebService::Braintree::PayPalAccount",
    };

    $self->setup_sub_objects($self, $attributes, $sub_objects);
    $self->set_attributes_from_hash($self, $attributes);
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 payment_types()

This returns a list of all the payment types supported by this class.

=cut

sub payment_types {
    return qw(credit_cards paypal_accounts);
}

=head2 payment_methods()

This returns an arrayref of all available payment methods across all types.

=cut

sub payment_methods {
    my $self = shift;

    my @methods = map {
        @{$self->$_ // []}
    } $self->payment_types;

    return \@methods;
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
