# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CustomerSearch;
$WebService::Braintree::CustomerSearch::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CustomerSearch

=head1 PURPOSE

This class represents a search for customers.

This class should never be instantiated directly. Instead, you will access
objects of this class through the search interface.

=cut

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

=head1 FIELDS

=cut

=head2 address_country_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific country name.

=cut

__PACKAGE__->text_field("address_country_name");

=head2 address_extended_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific extended address.

=cut

__PACKAGE__->text_field("address_extended_address");

=head2 address_first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific first name on the address.

=cut

__PACKAGE__->text_field("address_first_name");

=head2 address_last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific last name on the address.

=cut

__PACKAGE__->text_field("address_last_name");

=head2 address_locality

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific locality.

=cut

__PACKAGE__->text_field("address_locality");

=head2 address_postal_code

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific postal code.

=cut

__PACKAGE__->text_field("address_postal_code");

=head2 address_region

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific region.

=cut

__PACKAGE__->text_field("address_region");

=head2 address_street_address

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific street address.

=cut

__PACKAGE__->text_field("address_street_address");

=head2 cardholder_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific cardholder name.

=cut

__PACKAGE__->text_field("cardholder_name");

=head2 company

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific company.

=cut

__PACKAGE__->text_field("company");

=head2 created_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to customers created between the two dates.

=cut

__PACKAGE__->range_field("created_at");

=head2 credit_card_expiration_date

This is an L<equality field|WebService::Braintree::AdvancedSearchNodes/"Equality Field">. It will restrict the search to customers with
credit cards with a specific expiration date.

=cut

__PACKAGE__->equality_field("credit_card_expiration_date");

=head2 credit_card_number

This is a L<partial-match field|WebService::Braintree::AdvancedSearchNodes/"Partial Match Field">. It will restrict the search to customers with
credit cards containing a specific card number.

=cut

__PACKAGE__->partial_match_field("credit_card_number");

=head2 email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific email.

=cut

__PACKAGE__->text_field("email");

=head2 fax

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific fax.

=cut

__PACKAGE__->text_field("fax");

=head2 first_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific first name.

=cut

__PACKAGE__->text_field("first_name");

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field("id");

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of specific ids.

=cut

__PACKAGE__->multiple_values_field("ids");

=head2 last_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific last name.

=cut

__PACKAGE__->text_field("last_name");

=head2 payment_method_token

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific payment method token.

=cut

__PACKAGE__->text_field("payment_method_token");

=head2 payment_method_token_with_duplicates

This is an L<is field|WebService::Braintree::AdvancedSearchNodes/"is Field">. It will restrict the search to cusotmers with a specific payment method token.

=cut

__PACKAGE__->is_field("payment_method_token_with_duplicates");

=head2 paypal_account_email

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific paypal account email.

=cut

__PACKAGE__->text_field("paypal_account_email");

=head2 phone

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific phone.

=cut

__PACKAGE__->text_field("phone");

=head2 website

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific website.

=cut

__PACKAGE__->text_field("website");

__PACKAGE__->meta->make_immutable;

1;
__END__
