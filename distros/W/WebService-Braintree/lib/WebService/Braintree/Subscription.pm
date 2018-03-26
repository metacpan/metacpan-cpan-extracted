# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Subscription;
$WebService::Braintree::Subscription::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::Subscription

=head1 PURPOSE

This class creates, finds, updates, cancels, retries charges on, searches for,
and lists all subscriptions.

=cut

use WebService::Braintree::SubscriptionGateway;
use WebService::Braintree::Subscription::Status;

use Moose;

with 'WebService::Braintree::Role::Interface';

=head1 CLASS METHODS

=head2 create()

This takes a hashref of parameters and returns the subscription created.

=cut

sub create {
    my ($class, $params) = @_;
    $class->gateway->subscription->create($params);
}

=head2 find()

This takes a subscription_id and returns the subscription (if it exists).

=cut

sub find {
    my ($class, $id) = @_;
    $class->gateway->subscription->find($id);
}

=head2 update()

This takes a subcsription_id and a hashref of parameters. It will update the
corresponding subscription (if found) and returns the updated subscription.

=cut

sub update {
    my ($class, $id, $params) = @_;
    $class->gateway->subscription->update($id, $params);
}

=head2 cancel()

This takes a subscription_id and cancels (aka, deletes) the corresponding
subscription (if found).

=cut

sub cancel {
    my ($class, $id) = @_;
    $class->gateway->subscription->cancel($id);
}

=head2 retry_charge()

This takes a subscription_id and an amount and attempts to retry a charge for
that amount to that subscription (if found).

=cut

sub retry_charge {
    my ($class, $subscription_id, $amount) = @_;
    $class->gateway->transaction->retry_subscription_charge($subscription_id, $amount);
}

=head2 search()

This takes a subref which is used to set the search parameters and returns a
subscription object.

Please see L<Searching|WebService::Braintree/SEARCHING> for more information on
the subref and how it works.

Please see L<WebService::Braintree::SubscriptionSearch> for the fields available
to be searched on.

=cut

sub search {
    my($class, $block) = @_;
    $class->gateway->subscription->search($block);
}

=head2 all()

This returns all the subscriptions.

=cut

sub all {
    my $class = shift;
    $class->gateway->subscription->all;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
