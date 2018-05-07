# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CustomerSearch;
$WebService::Braintree::CustomerSearch::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CustomerSearch

=head1 PURPOSE

This class represents a search for customers.

This class should never be instantiated directly. Instead, you will access
objects of this class through the search interface.

=cut

use Moose;
extends 'WebService::Braintree::AdvancedSearch';

=head1 FIELDS

=cut

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

=head2 address_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific country name.

=cut

$field->text("address_country_name");

=head2 address_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific extended address.

=cut

$field->text("address_extended_address");

=head2 address_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific first name on the address.

=cut

$field->text("address_first_name");

=head2 address_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific last name on the address.

=cut

$field->text("address_last_name");

=head2 address_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific locality.

=cut

$field->text("address_locality");

=head2 address_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific postal code.

=cut

$field->text("address_postal_code");

=head2 address_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific region.

=cut

$field->text("address_region");

=head2 address_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific street address.

=cut

$field->text("address_street_address");

=head2 cardholder_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific cardholder name.

=cut

$field->text("cardholder_name");

=head2 company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific company.

=cut

$field->text("company");

=head2 created_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to customers created between the two dates.

=cut

$field->range("created_at");

=head2 credit_card_expiration_date

This is an L<equality field|WebService::Braintree::AdvancedSearchNodes/"Equality Field">. It will restrict the search to customers with
credit cards with a specific expiration date.

=cut

$field->equality("credit_card_expiration_date");

=head2 credit_card_number

This is a L<partial-match field|WebService::Braintree::AdvancedSearchNodes/"Partial Match Field">. It will restrict the search to customers with
credit cards containing a specific card number.

=cut

$field->partial_match("credit_card_number");

=head2 email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific email.

=cut

$field->text("email");

=head2 fax

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific fax.

=cut

$field->text("fax");

=head2 first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific first name.

=cut

$field->text("first_name");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

$field->text("id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

$field->multiple_values("ids");

=head2 last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific last name.

=cut

$field->text("last_name");

=head2 payment_method_token

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific payment method token.

=cut

$field->text("payment_method_token");

=head2 payment_method_token_with_duplicates

This is an L<is field|WebService::Braintree::AdvancedSearchNodes/"is Field">. It will restrict the search to cusotmers with a specific payment method token.

=cut

$field->is("payment_method_token_with_duplicates");

=head2 paypal_account_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific paypal account email.

=cut

$field->text("paypal_account_email");

=head2 phone

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific phone.

=cut

$field->text("phone");

=head2 website

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific website.

=cut

$field->text("website");

__PACKAGE__->meta->make_immutable;

1;
__END__
