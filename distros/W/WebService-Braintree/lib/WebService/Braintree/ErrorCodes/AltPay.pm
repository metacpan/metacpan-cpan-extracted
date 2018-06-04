# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::AltPay;
$WebService::Braintree::ErrorCodes::AltPay::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::AltPay

=head1 PURPOSE

This class contains error codes that might be returned if an alternate
payment method is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item PayPalAccountCannotHaveBothAccessTokenAndConsentCode

=cut

use constant PayPalAccountCannotHaveBothAccessTokenAndConsentCode => '82903';

=item PayPalAccountCannotVaultOneTimeUsePayPalAccount

=cut

use constant PayPalAccountCannotVaultOneTimeUsePayPalAccount => '82902';


=item PayPalAccountConsentCodeOrAccessTokenIsRequired

=cut

use constant PayPalAccountConsentCodeOrAccessTokenIsRequired => '82901';

=item PayPalAccountCustomerIdIsRequiredForVaulting

=cut

use constant PayPalAccountCustomerIdIsRequiredForVaulting => '82905';

=item PayPalAccountPaymentMethodNonceConsumed

=cut

use constant PayPalAccountPaymentMethodNonceConsumed => '92907';

=item PayPalAccountPaymentMethodNonceLocked

=cut

use constant PayPalAccountPaymentMethodNonceLocked => '92909';

=item PayPalAccountPaymentMethodNonceUnknown

=cut

use constant PayPalAccountPaymentMethodNonceUnknown => '92908';

=item PayPalAccountPayPalAccountSAreNotAccepted

=cut

use constant PayPalAccountPayPalAccountSAreNotAccepted => '82904';

=item PayPalAccountPayPalCommunicationError

=cut

use constant PayPalAccountPayPalCommunicationError => '92910';

=item PayPalAccountTokenIsInUse

=cut

use constant PayPalAccountTokenIsInUse => '92906';


=item SepaBankAccountAccountHolderNameIsRequired

=cut

use constant SepaBankAccountAccountHolderNameIsRequired => '93003';

=item SepaBankAccountBicIsRequired

=cut

use constant SepaBankAccountBicIsRequired => '93002';

=item SepaBankAccountIbanIsRequired

=cut

use constant SepaBankAccountIbanIsRequired => '93001';


=item SepaMandateAccountHolderNameIsRequired

=cut

use constant SepaMandateAccountHolderNameIsRequired => '83301';

=item SepaMandateBicInvalidCharacter

=cut

use constant SepaMandateBicInvalidCharacter => '83306';

=item SepaMandateBicIsRequired

=cut

use constant SepaMandateBicIsRequired => '83302';

=item SepaMandateBicLengthIsInvalid

=cut

use constant SepaMandateBicLengthIsInvalid => '83307';

=item SepaMandateBicUnsupportedCountry

=cut

use constant SepaMandateBicUnsupportedCountry => '83308';

=item SepaMandateBillingAddressConflict

=cut

use constant SepaMandateBillingAddressConflict => '93312';

=item SepaMandateBillingAddressIdIsInvalid

=cut

use constant SepaMandateBillingAddressIdIsInvalid => '93313';

=item SepaMandateIbanInvalidCharacter

=cut

use constant SepaMandateIbanInvalidCharacter => '83305';

=item SepaMandateIbanInvalidFormat

=cut

use constant SepaMandateIbanInvalidFormat => '83310';

=item SepaMandateIbanIsRequired

=cut

use constant SepaMandateIbanIsRequired => '83303';

=item SepaMandateIbanUnsupportedCountry

=cut

use constant SepaMandateIbanUnsupportedCountry => '83309';

=item SepaMandateLocaleIsUnsupported

=cut

use constant SepaMandateLocaleIsUnsupported => '93311';

=item SepaMandateTypeIsRequired

=cut

use constant SepaMandateTypeIsRequired => '93304';

=back

=cut

1;
__END__
