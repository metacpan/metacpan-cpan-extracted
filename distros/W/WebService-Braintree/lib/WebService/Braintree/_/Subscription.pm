# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Subscription;
$WebService::Braintree::_::Subscription::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Subscription

=head1 PURPOSE

This class represents a subscription.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;
use MooseX::Aliases;

extends 'WebService::Braintree::_';

=head1 ATTRIBUTES

=cut

use WebService::Braintree::_::AddOn;
use WebService::Braintree::_::Descriptor;
use WebService::Braintree::_::Discount;
use WebService::Braintree::_::Subscription::StatusDetail;
use WebService::Braintree::_::Transaction;

=head2 add_ons()

This returns the subscription's add-ons (if any). This will be an arrayref
of L<WebService::Braintree::_::AddOn/>.

=cut

has add_ons => (
    is => 'ro',
    isa => 'ArrayRefOfAddOn',
    coerce => 1,
);

=head2 balance()

This is the balance for this subscription.

=cut

# Coerce to "big_decimal"
has balance => (
    is => 'ro',
);

=head2 billing_day_of_month()

This is the billing day of month for this subscription.

=cut

has billing_day_of_month => (
    is => 'ro',
);

=head2 billing_period_end_date()

This is the billing period end date for this subscription.

=cut

# Coerce this to DateTime
has billing_period_end_date => (
    is => 'ro',
);

=head2 billing_period_start_date()

This is the billing period start date for this subscription.

=cut

# Coerce this to DateTime
has billing_period_start_date => (
    is => 'ro',
);

=head2 created_at()

This is when this subscription was created.

=cut

# Coerce this to DateTime
has created_at => (
    is => 'ro',
);

=head2 current_billing_cycle()

This is the current billing cycle for this subscription.

=cut

has current_billing_cycle => (
    is => 'ro',
);

=head2 days_past_due()

This is the days past due for this subscription.

=cut

# Coerce this to Int
has days_past_due => (
    is => 'ro',
);

=head2 description()

This is the description for this subscription.

=cut

has description => (
    is => 'ro',
);

=head2 descriptor()

This returns the subscription's descriptor (if it exists). This will be an
object of type L<WebService::Braintree::_::Descriptor/>.

=cut

has descriptor => (
    is => 'ro',
    isa => 'WebService::Braintree::_::Descriptor',
    coerce => 1,
);

=head2 discounts()

This returns the subscription's discounts (if any). This will be an arrayref
of L<WebService::Braintree::_::Discount/>.

=cut

has discounts => (
    is => 'ro',
    isa => 'ArrayRefOfDiscount',
    coerce => 1,
);

=head2 failure_count()

This is the failure count for this subscription.

=cut

# Coerce this to Int
has failure_count => (
    is => 'ro',
);

=head2 first_billing_date()

This is the first billing date for this subscription.

=cut

# Coerce this to DateTime
has first_billing_date => (
    is => 'ro',
);

=head2 id()

This is the id for this subscription.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_account_id()

This is the merchant account id for this subscription.

=cut

has merchant_account_id => (
    is => 'ro',
);

=head2 never_expires()

This is true if this subscription never expires.

C<< is_never_expires() >> is an alias for this attribute.

=cut

has never_expires => (
    is => 'ro',
    alias => 'is_never_expires',
);

=head2 next_billing_date()

This is the next_billing_date for this subscription.

=cut

# Coerce to DateTime
has next_billing_date => (
    is => 'ro',
);

=head2 next_billing_period_amount()

This is the next billing period amount for this subscription.

C<< next_bill_amount() >> is a deprecated alias for this attribute.

=cut

has next_billing_period_amount => (
    is => 'ro',
);

=head2 number_of_billing_cycles()

This is the number of billing cycles for this subscription.

=cut

# Coerce this to Int (?)
has number_of_billing_cycles => (
    is => 'ro',
);

=head2 paid_through_date()

This is the paid-through date for this subscription.

=cut

# Coerce this to DateTime
has paid_through_date => (
    is => 'ro',
);

=head2 payment_method_token()

This is the payment-method token for this subscription.

=cut

has payment_method_token => (
    is => 'ro',
);

=head2 plan_id()

This is the plan id for this subscription.

=cut

has plan_id => (
    is => 'ro',
);

=head2 price()

This is the price for this subscription.

=cut

# Coerce to "big_decimal"
has price => (
    is => 'ro',
);

=head2 status()

This is the status for this subscription.

=cut

has status => (
    is => 'ro',
);

=head2 status_history()

This returns the subscription's status history (if any). This will be an arrayref
of L<WebService::Braintree::_::Subscription::StatusDetail/>.

=cut

has status_history => (
    is => 'ro',
    isa => 'ArrayRefOfSubscriptionStatusDetail',
    coerce => 1,
    default => sub { [] },
);

=head2 transactions()

This returns the subscription's transactions (if any). This will be an arrayref
of L<WebService::Braintree::_::Transaction/>.

=cut

has transactions => (
    is => 'ro',
    isa => 'ArrayRefOfTransaction',
    coerce => 1,
);

=head2 trial_duration()

This is the trial period duration for this subscription.

=cut

# Coerce this to Int (?)
has trial_duration => (
    is => 'ro',
);

=head2 trial_duration_unit()

This is the unit for the L</trial_duration> for this subscription.

=cut

has trial_duration_unit => (
    is => 'ro',
);

=head2 trial_period()

This is the trial period for this subscription.

=cut

has trial_period => (
    is => 'ro',
);

=head2 updated_at()

This is when this subscription was last updated. If it has never been updated,
then this should equal the L</created_at> date.

=cut

# Coerce this to a DateTime
has updated_at => (
    is => 'ro',
);

# This cannot be a Moose alias because both parameters are passed in. The Ruby
# SDK only takes the "next_billing_period_amount" parameter and has marked
# next_bill_amount as deprecated.
sub next_bill_amount { shift->next_billing_period_amount }

__PACKAGE__->meta->make_immutable;

1;
__END__
