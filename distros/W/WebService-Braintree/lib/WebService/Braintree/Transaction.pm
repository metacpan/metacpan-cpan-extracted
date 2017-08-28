package WebService::Braintree::Transaction;
$WebService::Braintree::Transaction::VERSION = '0.93';
=head1 NAME

WebService::Braintree::Transaction

=head1 PURPOSE

This class generates and manages transactions.

=cut

use WebService::Braintree::Transaction::CreatedUsing;
use WebService::Braintree::Transaction::EscrowStatus;
use WebService::Braintree::Transaction::Source;
use WebService::Braintree::Transaction::Status;
use WebService::Braintree::Transaction::Type;

use Moose;
extends "WebService::Braintree::ResultObject";

=head1 CLASS METHODS

=head2 sale()

This takes a hashref of parameters and returns the transaction created. This is
a wrapper around L</create()> with the type set to 'sale'.

=cut

sub sale {
    my ($class, $params) = @_;
    $class->create($params, 'sale');
}

=head2 credit()

This takes a hashref of parameters and returns the transaction created. This is
a wrapper around L</create()> with the type set to 'credit'.

=cut

sub credit {
    my ($class, $params) = @_;
    $class->create($params, 'credit');
}

=head2 credit()

This takes a hashref of parameters and a type and returns the transaction
created.

In general, you will not call this method. Instead, call one of the wrappers
of this method, such as L</sale()> and L</credit()>.

=cut

sub create {
    my ($class, $params, $type) = @_;
    $params->{'type'} = $type;
    $class->gateway->transaction->create($params);
}

=head2 find()

This takes an id and returns the transaction (if it exists).

=cut

sub find {
    my ($class, $id) = @_;
    $class->gateway->transaction->find($id);
}

=head2 clone_transaction()

This takes an id and a hashref of parameters and clones the transaction (if it
exists) with the parameters as overrides.

=cut

sub clone_transaction {
    my ($class, $id, $params) = @_;
    $class->gateway->transaction->clone_transaction($id, $params);
}

=head2 void()

This takes an id and voids the transaction (if it exists).

=cut

sub void {
    my ($class, $id) = @_;
    $class->gateway->transaction->void($id);
}

=head2 submit_for_settlement()

This takes an id and an optional amount and submits the transaction (if it
exists) for settlement.

=cut

sub submit_for_settlement {
    my ($class, $id, $amount) = @_;
    my $params = {};
    $params->{'amount'} = $amount if $amount;
    $class->gateway->transaction->submit_for_settlement($id, $params);
}

=head2 refund()

This takes an id and an optional amount and refunds the transaction (if it
exists).

=cut

sub refund {
    my ($class, $id, $amount) = @_;
    my $params = {};
    $params->{'amount'} = $amount if $amount;
    $class->gateway->transaction->refund($id, $params);
}

=head2 hold_in_escrow()

This takes an id and holds the transaction (if it exists) in escrow.

=cut

sub hold_in_escrow {
    my ($class, $id) = @_;
    $class->gateway->transaction->hold_in_escrow($id);
}

=head2 release_from_escrow()

This takes an id and releases the transaction (if it exists) from escrow.

=cut

sub release_from_escrow {
    my ($class, $id) = @_;
    $class->gateway->transaction->release_from_escrow($id);
}

=head2 cancel_release()

This takes an id and cancels the release of the transaction (if it exists).

=cut

sub cancel_release {
    my ($class, $id) = @_;
    $class->gateway->transaction->cancel_release($id);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
transaction object.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

=cut

sub search {
    my ($class, $block) = @_;
    $class->gateway->transaction->search($block);
}

=head2 all()

This returns all the transactions.

=cut

sub all {
    my $class = shift;
    $class->gateway->transaction->all;
}

sub gateway {
    WebService::Braintree->configuration->gateway;
}

=head1 OBJECT METHODS

In addition to the methods provided by the keys returned from Braintree, this
class provides the following methods:

=head2 disbursement_details()

This returns the disbursement details of this transaction (if they exist). It
will be a L<WebService::Braintree::DisbursementDetails> object.

=cut

has disbursement_details => (is => 'rw');

=head2 paypal_details()

This returns the PayPal details of this transaction (if they exist). It
will be a L<WebService::Braintree::PayPalDetails> object.

=cut

has paypal_details => (is => 'rw');

=head2 subscription()

This returns the related subscription of this transaction (if they exist). It
will be a L<WebService::Braintree::Subscription> object.

=cut

has subscription => (is => 'rw');

sub BUILD {
    my ($self, $attributes) = @_;
    my $sub_objects = {
        disputes => 'WebService::Braintree::Dispute',
    };

    $self->subscription(WebService::Braintree::Subscription->new($attributes->{subscription})) if ref($attributes->{subscription}) eq 'HASH';
    delete($attributes->{subscription});

    $self->disbursement_details(WebService::Braintree::DisbursementDetails->new($attributes->{disbursement_details})) if ref($attributes->{disbursement_details}) eq 'HASH';
    delete($attributes->{disbursement_details});

    $self->paypal_details(WebService::Braintree::PayPalDetails->new($attributes->{paypal})) if ref($attributes->{paypal}) eq 'HASH';
    delete($attributes->{paypal});

    $self->setup_sub_objects($self, $attributes, $sub_objects);
    $self->set_attributes_from_hash($self, $attributes);
}

=head2 is_disbursed()

This returns whether or not the disbursement details of this transaction are
valid.

=cut

sub is_disbursed {
    my $self = shift;
    $self->disbursement_details->is_valid();
};

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
