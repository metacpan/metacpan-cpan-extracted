# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::DisputeSearch;
$WebService::Braintree::DisputeSearch::VERSION = '1.4';
use 5.010_001;
use strictures 1;

use Moose;

=head1 NAME

WebService::Braintree::DisputeSearch

=head1 PURPOSE

This class represents a search for disputes.

=cut

extends 'WebService::Braintree::AdvancedSearch';

=head1 FIELDS

=cut

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

=head2 case_number

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific case number.

=cut

$field->text("case_number");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

$field->text("id");

=head2 reference_number

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific reference number.

=cut

$field->text("reference_number");

=head2 transaction_id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific transaction.

=cut

$field->text("transaction_id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

$field->multiple_values("ids");

=head2 merchant_account_id

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific merchant accounts.

=cut

$field->multiple_values("merchant_account_id");

=head2 reason

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific reasons.

=cut

$field->multiple_values("reason");

=head2 reason_code

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific reason codes.

=cut

$field->multiple_values("reason_code");

=head2 status

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific statuses.

=cut

$field->multiple_values("status");

=head2 transaction_source

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific transaction sources.

=cut

$field->multiple_values("transaction_source");


=head2 amount_disputed

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the amounts.

=cut

$field->range("amount_disputed");

=head2 amount_won

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the amounts.

=cut

$field->range("amount_won");

=head2 received_date

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the two dates.

=cut

$field->range("received_date");

=head2 reply_by_date

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to disputes created between the two dates.

=cut

$field->range("reply_by_date");

__PACKAGE__->meta->make_immutable;

1;
__END__
