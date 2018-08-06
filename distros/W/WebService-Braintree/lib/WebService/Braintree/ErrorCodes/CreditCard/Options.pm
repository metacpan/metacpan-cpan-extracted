# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::CreditCard::Options;
$WebService::Braintree::ErrorCodes::CreditCard::Options::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::CreditCard::Options

=head1 PURPOSE

This class contains error codes that might be returned if the options for
a credit card are incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item UpdateExistingTokenIsInvalid

=cut

use constant UpdateExistingTokenIsInvalid => '91723';

=item UseBillingForShippingDisabled

=cut

use constant UseBillingForShippingDisabled => '91572';

=item VerificationMerchantAccountIdIsInvalid

=cut

use constant VerificationMerchantAccountIdIsInvalid => '91728';

=back

=cut

1;
__END__
