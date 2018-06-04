# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::PayPalAccount;
$WebService::Braintree::ErrorCodes::PayPalAccount::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::PayPalAccount

=head1 PURPOSE

This class contains error codes that might be returned if a PayPalAccount
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CannotCloneTransactionWithPayPalAccount

=cut

use constant CannotCloneTransactionWithPayPalAccount => '91573';

=item CannotVaultOneTimeUsePayPalAccount

=cut

use constant CannotVaultOneTimeUsePayPalAccount => '82902';

=item CannotHaveBothAccessTokenAndConsentCode

=cut

use constant CannotHaveBothAccessTokenAndConsentCode => '82903';

=item ConsentCodeOrAccessTokenIsRequired

=cut

use constant ConsentCodeOrAccessTokenIsRequired => '82901';

=item CustomerIdIsRequiredForVaulting

=cut

use constant CustomerIdIsRequiredForVaulting => '82905';

=item PaymentMethodNonceConsumed

=cut

use constant PaymentMethodNonceConsumed => '92907';

=item PaymentMethodNonceLocked

=cut

use constant PaymentMethodNonceLocked => '92909';

=item PaymentMethodNonceUnknown

=cut

use constant PaymentMethodNonceUnknown => '92908';

=item PayPalAccountsAreNotAccepted

=cut

use constant PayPalAccountsAreNotAccepted => '82904';

=item PayPalCommunicationError

=cut

use constant PayPalCommunicationError => '92910';

=item TokenIsInUse

=cut

use constant TokenIsInUse => '92906';

=back

=cut

1;
__END__
