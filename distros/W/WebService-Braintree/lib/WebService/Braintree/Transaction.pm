# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Transaction;
$WebService::Braintree::Transaction::VERSION = '1.7';
use 5.010_001;
use strictures 1;

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

use Moo;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 sale()

This takes a hashref of parameters and returns the transaction created.

=cut

sub sale {
    my ($class, $params) = @_;
    $class->gateway->transaction->sale($params);
}

=head2 credit()

This takes a hashref of parameters and returns the transaction created.

=cut

sub credit {
    my ($class, $params) = @_;
    $class->gateway->transaction->credit($params);
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

This takes an id, an optional amount, amount, and optional parameters and submits the transaction
for settlement.

=cut

sub submit_for_settlement {
    my ($class, $id, $amount, $params) = @_;
    $class->gateway->transaction->submit_for_settlement($id, $amount, ($params // {}));
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

=head2 update_details()

This takes an id and updates the transaction details with the provided
parameters. This requires the transaction to be in submitted_for_settlement
status.

=cut

sub update_details {
    my ($class, $id, $params) = @_;
    $class->gateway->transaction->update_details($id, ($params // {}));
}

=head2 submit_for_partial_settlement()

This takes an id, amount, and optional parameters and submits the transaction
for partial settlement.

=cut

sub submit_for_partial_settlement {
    my ($class, $id, $amount, $params) = @_;
    $class->gateway->transaction->submit_for_partial_settlement($id, $amount, ($params // {}));
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

__PACKAGE__->meta->make_immutable;

1;
__END__
