# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::Business;
$WebService::Braintree::ErrorCodes::MerchantAccount::Business::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::Business

=head1 PURPOSE

This class contains error codes that might be returned if a business record
for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item DbaNameIsInvalid

=cut

use constant DbaNameIsInvalid => "82646";

=item TaxIdIsInvalid

=cut

use constant TaxIdIsInvalid => "82647";

=item TaxIdIsRequiredWithLegalName

=cut

use constant TaxIdIsRequiredWithLegalName => "82648";

=item LegalNameIsRequiredWithTaxId

=cut

use constant LegalNameIsRequiredWithTaxId => "82669";

=item TaxIdMustBeBlank

=cut

use constant TaxIdMustBeBlank => "82672";

=item LegalNameIsInvalid

=cut

use constant LegalNameIsInvalid => "82677";

=back

=cut

1;
__END__
