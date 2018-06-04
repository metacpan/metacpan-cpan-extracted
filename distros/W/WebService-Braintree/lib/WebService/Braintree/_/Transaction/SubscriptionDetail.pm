# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Transaction::SubscriptionDetail;
$WebService::Braintree::_::Transaction::SubscriptionDetail::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Transaction::SubscriptionDetail

=head1 PURPOSE

This class represents a subscription detail of a transaction.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 billing_period_end_date()

This is the end date of the billing period for this subscription detail.

=cut

has billing_period_end_date => (
    is => 'ro',
);

=head2 billing_period_start_date()

This is the start date of the billing period for this subscription detail.

=cut

has billing_period_start_date => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
