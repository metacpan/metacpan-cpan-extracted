# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::DisputeSearch;
$WebService::Braintree::DisputeSearch::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::DisputeSearch

=head1 PURPOSE

This class represents a search for disputes.

=cut

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

=head1 FIELDS

=cut

=head2 case_number

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific case number.

=cut

__PACKAGE__->text_field("case_number");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field("id");

=head2 reference_number

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific reference number.

=cut

__PACKAGE__->text_field("reference_number");

=head2 transaction_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific transaction.

=cut

__PACKAGE__->text_field("transaction_id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

__PACKAGE__->multiple_values_field("ids");

=head2 merchant_account_id

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific merchant accounts.

=cut

__PACKAGE__->multiple_values_field("merchant_account_id");

=head2 reason

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific reasons.

=cut

__PACKAGE__->multiple_values_field("reason");

=head2 reason_code

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific reason codes.

=cut

__PACKAGE__->multiple_values_field("reason_code");

=head2 status

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific statuses.

=cut

__PACKAGE__->multiple_values_field("status");

=head2 transaction_source

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction sources.

=cut

__PACKAGE__->multiple_values_field("transaction_source");


=head2 amount_disputed

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the amounts.

=cut

__PACKAGE__->range_field("amount_disputed");

=head2 amount_won

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the amounts.

=cut

__PACKAGE__->range_field("amount_won");

=head2 received_date

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the two dates.

=cut

__PACKAGE__->range_field("received_date");

=head2 reply_by_date

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the two dates.

=cut

__PACKAGE__->range_field("reply_by_date");

__PACKAGE__->meta->make_immutable;

1;
__END__
