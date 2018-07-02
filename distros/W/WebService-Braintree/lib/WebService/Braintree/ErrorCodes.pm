# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes;
$WebService::Braintree::ErrorCodes::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes

=head1 PURPOSE

This class loads all the constants representing error codes that the API might
return.

This class is never instantiated or interfaced with. Instead, you will interface
with the classes listed in this document.

=head1 USAGE

TODO: Explain how the error codes are used vis-a-vis ValidationErrorCollection

=cut

# TODO: Maybe convert this into an auto-loader?

=head1 CLASSES

=over 4

=item L<WebService::Braintree::ErrorCodes::Address>

=cut

use WebService::Braintree::ErrorCodes::Address;

=item L<WebService::Braintree::ErrorCodes::AltPay>

=cut

use WebService::Braintree::ErrorCodes::AltPay;

=item L<WebService::Braintree::ErrorCodes::ApplePay>

=cut

use WebService::Braintree::ErrorCodes::ApplePay;

=item L<WebService::Braintree::ErrorCodes::AuthorizationFingerprint>

=cut

use WebService::Braintree::ErrorCodes::AuthorizationFingerprint;

=item L<WebService::Braintree::ErrorCodes::ClientToken>

=cut

use WebService::Braintree::ErrorCodes::ClientToken;

=item L<WebService::Braintree::ErrorCodes::CreditCard>

=cut

use WebService::Braintree::ErrorCodes::CreditCard;

=item L<WebService::Braintree::ErrorCodes::CreditCard::Options>

=cut

use WebService::Braintree::ErrorCodes::CreditCard::Options;

=item L<WebService::Braintree::ErrorCodes::Customer>

=cut

use WebService::Braintree::ErrorCodes::Customer;

=item L<WebService::Braintree::ErrorCodes::Descriptor>

=cut

use WebService::Braintree::ErrorCodes::Descriptor;

=item L<WebService::Braintree::ErrorCodes::Dispute>

=cut

use WebService::Braintree::ErrorCodes::Dispute;

=item L<WebService::Braintree::ErrorCodes::DocumentUpload>

=cut

use WebService::Braintree::ErrorCodes::DocumentUpload;

=item L<WebService::Braintree::ErrorCodes::IndustryType>

=cut

use WebService::Braintree::ErrorCodes::IndustryType;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::Address>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::Address;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::Business>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::Business;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::Business::Address>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::Business::Address;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::Funding>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::Funding;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::Individual>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::Individual;

=item L<WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address>

=cut

use WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address;

=item L<WebService::Braintree::ErrorCodes::PaymentMethod>

=cut

use WebService::Braintree::ErrorCodes::PaymentMethod;

=item L<WebService::Braintree::ErrorCodes::PayPalAccount>

=cut

use WebService::Braintree::ErrorCodes::PayPalAccount;

=item L<WebService::Braintree::ErrorCodes::SettlementBatchSummary>

=cut

use WebService::Braintree::ErrorCodes::SettlementBatchSummary;

=item L<WebService::Braintree::ErrorCodes::Subscription>

=cut

use WebService::Braintree::ErrorCodes::Subscription;

=item L<WebService::Braintree::ErrorCodes::Subscription::Modification>

=cut

use WebService::Braintree::ErrorCodes::Subscription::Modification;

=item L<WebService::Braintree::ErrorCodes::Transaction>

=cut

use WebService::Braintree::ErrorCodes::Transaction;

=item L<WebService::Braintree::ErrorCodes::Transaction::Options>

=cut

use WebService::Braintree::ErrorCodes::Transaction::Options;

=back

=cut

1;
__END__
