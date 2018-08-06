# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Customer;
$WebService::Braintree::Customer::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Customer

=head1 PURPOSE

This class creates, updates, deletes, and finds customers.

=cut

use Moo;

with 'WebService::Braintree::Role::Interface';

=head2 create()

This takes a hashref of parameters and returns a L<response|WebService::Braintee::Result> with the C<< customer() >> set.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->customer->create($params);
}

=head2 find()

This takes a token and returns a L<response|WebService::Braintee::Result> with
the C<< customer() >> set (if found).

=cut

sub find {
    my($class, $id) = @_;
    $class->gateway->customer->find($id);
}

=head2 update()

This takes a customer_id and a hashref of parameters. It will update the corresponding
credit card (if found) and return a L<response|WebService::Braintee::Result>
with the C<< customer() >> set.

=cut

sub update {
    my ($class, $id, $params) = @_;
    $class->gateway->customer->update($id, $params);
}

=head2 delete()

This takes a customer_id. It will delete the corresponding customer (if found)
and return a L<response|WebService::Braintee::Result> with the C<< customer() >>
set.

=cut

sub delete {
    my ($class, $id) = @_;
    $class->gateway->customer->delete($id);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
L<collection|WebService::Braintree::ResourceCollection> of the matching
L<customers|WebService::Braintree::_::Customer>.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

Please see L<WebService::Braintree::CustomerSearch> for more
information on what specfic fields you can set for this method.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->customer->search($block);
}

=head2 all()

This returns a L<collection|WebService::Braintree::ResourceCollection> of all
L<customers|WebService::Braintree::_::Customer>.

=cut

sub all {
    my ($class) = @_;
    $class->gateway->customer->all;
}

=head2 transactions()

This takes a customer_id. It returns a L<collection|WebService::Braintree::ResourceCollection> of all L<customers|WebService::Braintree::_::Transaction> for
that customer.

=cut

sub transactions {
    my ($class, $id) = @_;
    $class->gateway->customer->transactions($id);
}

=head2 credit()

This takes a customer_id and an optional hashref of parameters. This delegates
to L<WebService::Braintree::Transaction/credit>, setting the C<< customer_id >>
appropriately.

=cut

sub credit {
    my ($class, $id, $params) = @_;
    $class->gateway->transaction->credit({
        %{$params // {}},
        customer_id => $id,
    });
}

=head2 sale()

This takes a customer_id and an optional hashref of parameters. This delegates
to L<WebService::Braintree::Transaction/sale>, setting the C<< customer_id >>
appropriately.

=cut

sub sale {
    my ($class, $id, $params) = @_;
    $class->gateway->transaction->sale({
        %{$params // {}},
        customer_id => $id,
    });
}

__PACKAGE__->meta->make_immutable;

1;
__END__
