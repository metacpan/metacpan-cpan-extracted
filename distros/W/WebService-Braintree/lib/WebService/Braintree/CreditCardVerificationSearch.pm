# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::CreditCardVerificationSearch;
$WebService::Braintree::CreditCardVerificationSearch::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::CreditCardVerificationSearch

=head1 PURPOSE

This class represents a search for credit card verifications.

=cut

use Moo;
with 'WebService::Braintree::Role::AdvancedSearch';

use constant FIELDS => [];

use WebService::Braintree::CreditCard::CardType;

=head1 FIELDS

=cut

=head2 id

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to a specific id.

=cut

__PACKAGE__->text_field('id');

=head2 ids

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to a list of
specific ids.

=cut

__PACKAGE__->multiple_values_field('ids');

=head2 credit_card_cardholder_name

This is a L<text field|WebService::Braintree::AdvancedSearchNodes/"Text Field">. It will restrict the search to verifications for credit
cards with a specific cardholder name.

=cut

__PACKAGE__->text_field('credit_card_cardholder_name');

=head2 credit_card_expiration_date

This is an L<equality field|WebService::Braintree::AdvancedSearchNodes/"Equality Field">. It will restrict the search to verifications for
credit cards with a specific expiration date.

=cut

__PACKAGE__->equality_field('credit_card_expiration_date');

=head2 credit_card_number

This is a L<partial-match field|WebService::Braintree::AdvancedSearchNodes/"Partial Match Field">. It will restrict the search to verifications for
credit cards with a specific card number.

=cut

__PACKAGE__->partial_match_field('credit_card_number');

=head2 credit_card_card_type

This is a L<multiple-values field|WebService::Braintree::AdvancedSearchNodes/"Multiple Values Field">. It will restrict the search to verifications
for credit cards within the list of provided card types. The card types must be
within L<this list|WebService::Braintree::CreditCard::CardType/All>.

=cut

__PACKAGE__->multiple_values_field('credit_card_card_type', @{WebService::Braintree::CreditCard::CardType::All()});

=head2 created_at

This is a L<range field|WebService::Braintree::AdvancedSearchNodes/"Range Field">. It will restrict the search to verifications created
between the two dates.

=cut

__PACKAGE__->range_field('created_at');

__PACKAGE__->meta->make_immutable;

1;
__END__
