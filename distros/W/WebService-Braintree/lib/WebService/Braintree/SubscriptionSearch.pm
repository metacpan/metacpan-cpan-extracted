# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::SubscriptionSearch;
$WebService::Braintree::SubscriptionSearch::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::SubscriptionSearch

=head1 PURPOSE

This class represents a search for subscriptions.

This class should never be instantiated directly. Instead, you will access
objects of this class through the search interface.

=cut

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

use WebService::Braintree::Subscription::Status;

=head1 FIELDS

=cut

=head2 address_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific country name.

=cut

__PACKAGE__->text_field('address_country_name');

=head2 billing_cycles_remaining

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field('billing_cycles_remaining');

=head2 days_past_due

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field('days_past_due');

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field('id');

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

__PACKAGE__->multiple_values_field('ids');

=head2 in_trial_period

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to the provided list.

=cut

__PACKAGE__->multiple_values_field('in_trial_period');

=head2 merchant_account_id

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to the provided list.

=cut

__PACKAGE__->multiple_values_field('merchant_account_id');

=head2 next_billing_date

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field('next_billing_date');

=head2 plan_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field('plan_id');

=head2 price

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to subscriptions created between the two values.

=cut

__PACKAGE__->range_field('price');

=head2 status

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to the provided list.

This list is restricted to the values defined by L<WebService::Braintree::Subscription::Status/All>

=cut

__PACKAGE__->multiple_values_field('status', WebService::Braintree::Subscription::Status::All);

=head2 transaction_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field('transaction_id');

__PACKAGE__->meta->make_immutable;

1;
__END__
