# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails;
$WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::VERSION = '1.2';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails

=head1 PURPOSE

This class contains error codes that might be returned if the applicant
details for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item AccountNumberIsRequired

=cut

use constant AccountNumberIsRequired => '82614';

=item CompanyNameIsInvalid

=cut

use constant CompanyNameIsInvalid => '82631';

=item CompanyNameIsRequiredWithTaxId

=cut

use constant CompanyNameIsRequiredWithTaxId => '82633';

=item DateOfBirthIsRequired

=cut

use constant DateOfBirthIsRequired => '82612';

=item Declined

=cut

use constant Declined => '82626'; # Keep for backwards compatibility

=item DeclinedMasterCardMatch

=cut

use constant DeclinedMasterCardMatch => '82622'; # Keep for backwards compatibility

=item DeclinedOFAC

=cut

use constant DeclinedOFAC => '82621'; # Keep for backwards compatibility

=item DeclinedFailedKYC

=cut

use constant DeclinedFailedKYC => '82623'; # Keep for backwards compatibility

=item DeclinedSsnInvalid

=cut

use constant DeclinedSsnInvalid => '82624'; # Keep for backwards compatibility

=item DeclinedSsnMatchesDeceased

=cut

use constant DeclinedSsnMatchesDeceased => '82625'; # Keep for backwards compatibility

=item EmailAddressIsInvalid

=cut

use constant EmailAddressIsInvalid => '82616';

=item FirstNameIsInvalid

=cut

use constant FirstNameIsInvalid => '82627';

=item FirstNameIsRequired

=cut

use constant FirstNameIsRequired => '82609';

=item LastNameIsInvalid

=cut

use constant LastNameIsInvalid => '82628';

=item LastNameIsRequired

=cut

use constant LastNameIsRequired => '82611';

=item PhoneIsInvalid

=cut

use constant PhoneIsInvalid => '82636';

=item RoutingNumberIsInvalid

=cut

use constant RoutingNumberIsInvalid => '82635';

=item RoutingNumberIsRequired

=cut

use constant RoutingNumberIsRequired => '82613';

=item SsnIsInvalid

=cut

use constant SsnIsInvalid => '82615';

=item TaxIdIsInvalid

=cut

use constant TaxIdIsInvalid => '82632';

=item TaxIdIsRequiredWithCompanyName

=cut

use constant TaxIdIsRequiredWithCompanyName => '82634';

=item DateOfBirthIsInvalid

=cut

use constant DateOfBirthIsInvalid => '82663';

=item AccountNumberIsInvalid

=cut

use constant AccountNumberIsInvalid => '82670';

=item EmailAddressIsRequired

=cut

use constant EmailAddressIsRequired => '82665';

=item TaxIdMustBeBlank

=cut

use constant TaxIdMustBeBlank => '82673';

=back

=cut

1;
__END__
