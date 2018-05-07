# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::_::Plan;
$WebService::Braintree::_::Plan::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::_::Plan

=head1 PURPOSE

This class represents a subscription plan.

This class will only be created as part of a L<response|WebService::Braintree::Result> or L<error response|WebService::Braintree::ErrorResult>.

=cut

use Moose;

extends 'WebService::Braintree::_';

use WebService::Braintree::_::AddOn;
use WebService::Braintree::_::Discount;

=head1 ATTRIBUTES

=cut

=head2 add_ons()

This returns the plan's discounts. This will be an arrayref of
L<add-ons|WebService::Braintree::_::AddOn/>.

=cut

has add_ons => (
    is => 'ro',
    isa => 'ArrayRefOfAddOn',
    coerce => 1,
);

=head2 billing_day_of_month()

This returns the plan's billing day of month.

=cut

has billing_day_of_month => (
    is => 'ro',
);

=head2 billing_frequency()

This returns the plan's billing frequency.

=cut

has billing_frequency => (
    is => 'ro',
);

=head2 created_at()

This returns when this plan was created.

=cut

has created_at => (
    is => 'ro',
);

=head2 currency_iso_code()

This returns the plan's currency ISO code.

=cut

has currency_iso_code => (
    is => 'ro',
);

=head2 description()

This returns the plan's description.

=cut

has description => (
    is => 'ro',
);

=head2 discounts()

This returns the plan's discounts. This will be an arrayref of
L<discounts|WebService::Braintree::_::Discount/>.

=cut

has discounts => (
    is => 'ro',
    isa => 'ArrayRefOfDiscount',
    coerce => 1,
);

=head2 id()

This returns the plan's ID.

=cut

has id => (
    is => 'ro',
);

=head2 merchant_id()

This returns the plan's merchant ID.

=cut

has merchant_id => (
    is => 'ro',
);

=head2 name()

This returns the plan's name.

=cut

has name => (
    is => 'ro',
);

=head2 number_of_billing_cycles()

This returns the plan's number of billing cycles.

=cut

has number_of_billing_cycles => (
    is => 'ro',
);

=head2 price()

This returns the plan's price.

=cut

# Coerce this to "big_decimal"
has price => (
    is => 'ro',
);

=head2 trial_duration()

This returns the plan's trial duration.

=cut

has trial_duration => (
    is => 'ro',
);

=head2 trial_duration_unit()

This returns the plan's unit of time for the trial duration.

=cut

has trial_duration_unit => (
    is => 'ro',
);

=head2 trial_period()

This returns the plan's trial period.

=cut

has trial_period => (
    is => 'ro',
);

=head2 updated_at()

This returns when this plan was last updated.

=cut

has updated_at => (
    is => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
