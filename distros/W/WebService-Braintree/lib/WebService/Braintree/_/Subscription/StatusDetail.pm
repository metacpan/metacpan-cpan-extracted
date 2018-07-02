# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Subscription::StatusDetail;
$WebService::Braintree::_::Subscription::StatusDetail::VERSION = '1.6';
use 5.010_001;
use strictures 1;

use Moo;

=head1 NAME

WebService::Braintree::_::Subscription::StatusDetail

=head1 PURPOSE

This class represents a subscription status history detail.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

=head2 balance()

This is the balance for this subscription status history detail.

=cut

# Coerce to "big_decimal"?
has balance => (
    is => 'ro',
);

=head2 currency_iso_code()

This is the currency ISO code for this subscription status history detail.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 plan_id()

This is the plan id for this subscription status history detail.

=cut

has plan_id => (
    is => 'ro',
);

=head2 price()

This is the price for this subscription status history detail.

=cut

has price => (
    is => 'ro',
);

=head2 status()

This is the status for this subscription status history detail.

=cut

has status => (
    is => 'ro',
);

=head2 subscription_source()

This is the subscription source for this subscription status history detail.

=cut

has subscription_source => (
    is => 'ro',
);

=head2 timestamp()

This is the timestamp for this subscription status history detail.

=cut

# Coerce this to DateTime (?)
has timestamp => (
    is => 'ro',
);

=head2 user()

This is the user for this subscription status history detail.

=cut

has user => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
