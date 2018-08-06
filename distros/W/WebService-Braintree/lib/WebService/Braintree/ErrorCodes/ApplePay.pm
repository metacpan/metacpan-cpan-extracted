# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::ApplePay;
$WebService::Braintree::ErrorCodes::ApplePay::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::ApplePay

=head1 PURPOSE

This class contains error codes that might be returned if an ApplePay
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item ApplePayCardsAreNotAccepted

=cut

use constant ApplePayCardsAreNotAccepted => '83501';

=item CannotUpdateApplePayCardUsingPaymentMethodNonce

=cut

use constant CannotUpdateApplePayCardUsingPaymentMethodNonce => '93507';

=item CertificateInvalid

=cut

use constant CertificateInvalid => '93517';

=item CryptogramIsRequired

=cut

use constant CryptogramIsRequired => '93511';

=item CustomerIdIsRequiredForVaulting

=cut

use constant CustomerIdIsRequiredForVaulting => '83502';

=item DecryptionFailed

=cut

use constant DecryptionFailed => '83512';

=item Disabled

=cut

use constant Disabled => '93513';

=item ExpirationMonthIsRequired

=cut

use constant ExpirationMonthIsRequired => '93509';

=item ExpirationYearIsRequired

=cut

use constant ExpirationYearIsRequired => '93510';

=item MerchantKeysAlreadyConfigured

=cut

use constant MerchantKeysAlreadyConfigured => '93515';

=item MerchantKeysNotConfigured

=cut

use constant MerchantKeysNotConfigured => '93516';

=item MerchantNotConfigured

=cut

use constant MerchantNotConfigured => '93514';

=item NumberIsRequired

=cut

use constant NumberIsRequired => '93508';

=item PaymentMethodNonceConsumed

=cut

use constant PaymentMethodNonceConsumed => '93504';

=item PaymentMethodNonceUnknown

=cut

use constant PaymentMethodNonceUnknown => '93505';

=item PaymentMethodNonceLocked

=cut

use constant PaymentMethodNonceLocked => '93506';

=item PaymentMethodNonceCardTypeIsNotAccepted

=cut

use constant PaymentMethodNonceCardTypeIsNotAccepted => '83518';

=item TokenIsInUse

=cut

use constant TokenIsInUse => '93503';

=back

=cut

1;
__END__
