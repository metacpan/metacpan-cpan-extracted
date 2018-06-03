# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::CreditCard;
$WebService::Braintree::ErrorCodes::CreditCard::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::CreditCard

=head1 PURPOSE

This class contains error codes that might be returned if a credit card
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item BillingAddressConflict

=cut

use constant BillingAddressConflict => '91701';

=item BillingAddressIdIsInvalid

=cut

use constant BillingAddressIdIsInvalid => '91702';

=item CannotUpdateCardUsingPaymentMethodNonce

=cut

use constant CannotUpdateCardUsingPaymentMethodNonce => '91735';

=item CardholderNameIsTooLong

=cut

use constant CardholderNameIsTooLong => '81723';

=item CreditCardTypeIsNotAccepted

=cut

use constant CreditCardTypeIsNotAccepted => '81703';

=item CreditCardTypeIsNotAcceptedBySubscriptionMerchantAccount

=cut

use constant CreditCardTypeIsNotAcceptedBySubscriptionMerchantAccount => '81718';

=item CustomerIdIsInvalid

=cut

use constant CustomerIdIsInvalid => '91705';

=item CustomerIdIsRequired

=cut

use constant CustomerIdIsRequired => '91704';

=item CvvIsInvalid

=cut

use constant CvvIsInvalid => '81707';

=item CvvIsRequired

=cut

use constant CvvIsRequired => '81706';

=item CvvVerificationFailed

=cut

use constant CvvVerificationFailed => '81736';

=item DuplicateCardExists

=cut

use constant DuplicateCardExists => '81724';

=item ExpirationDateConflict

=cut

use constant ExpirationDateConflict => '91708';

=item ExpirationDateIsInvalid

=cut

use constant ExpirationDateIsInvalid => '81710';

=item ExpirationDateIsRequired

=cut

use constant ExpirationDateIsRequired => '81709';

=item ExpirationDateYearIsInvalid

=cut

use constant ExpirationDateYearIsInvalid => '81711';

=item ExpirationMonthIsInvalid

=cut

use constant ExpirationMonthIsInvalid => '81712';

=item ExpirationYearIsInvalid

=cut

use constant ExpirationYearIsInvalid => '81713';

=item InvalidVenmoSDKPaymentMethodCode

=cut

use constant InvalidVenmoSDKPaymentMethodCode => '91727';

=item NumberHasInvalidLength

=cut

use constant NumberHasInvalidLength => '81716';

=item NumberIsInvalid

=cut

use constant NumberIsInvalid => '81715';

=item NumberIsRequired

=cut

use constant NumberIsRequired => '81714';

=item NumberLengthIsInvalid

=cut

use constant NumberLengthIsInvalid => '81716';

=item NumberMustBeTestNumber

=cut

use constant NumberMustBeTestNumber => '81717';

=item PaymentMethodCannotForwardPaymentMethodType

=cut

use constant PaymentMethodCannotForwardPaymentMethodType => '93107';

=item PaymentMethodConflict

=cut

use constant PaymentMethodConflict => '81725';

=item PaymentMethodNonceCardTypeIsNotAccepted

=cut

use constant PaymentMethodNonceCardTypeIsNotAccepted => '91734';

=item PaymentMethodNonceConsumed

=cut

use constant PaymentMethodNonceConsumed => '91731';

=item PaymentMethodNonceLocked

=cut

use constant PaymentMethodNonceLocked => '91733';

=item PaymentMethodNonceUnknown

=cut

use constant PaymentMethodNonceUnknown => '91732';

=item PostalCodeVerificationFailed

=cut

use constant PostalCodeVerificationFailed => '81737';

=item TokenFormatIsInvalid

=cut

use constant TokenFormatIsInvalid => '91718';

=item TokenInvalid

=cut

use constant TokenInvalid => '91718';

=item TokenIsInUse

=cut

use constant TokenIsInUse => '91719';

=item TokenIsNotAllowed

=cut

use constant TokenIsNotAllowed => '91721';

=item TokenIsRequired

=cut

use constant TokenIsRequired => '91722';

=item TokenIsTooLong

=cut

use constant TokenIsTooLong => '91720';

=item UpdateExistingTokenNotAllowed

=cut

use constant UpdateExistingTokenNotAllowed => '91729';

=item VerificationNotSupportedOnThisMerchantAccount

=cut

use constant VerificationNotSupportedOnThisMerchantAccount => '91730';

=item VerificationMerchantAccountIdIsInvalid

=cut

use constant VerificationMerchantAccountIdIsInvalid => '91728';

=item VenmoSDKPaymentMethodCodeCardTypeIsNotAccepted

=cut

use constant VenmoSDKPaymentMethodCodeCardTypeIsNotAccepted => '91726';

=back

=cut

1;
__END__
