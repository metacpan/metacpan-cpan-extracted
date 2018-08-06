# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::Address;
$WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::Address::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::Address

=head1 PURPOSE

This class contains error codes that might be returned if the address for an
applicant details for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item LocalityIsRequired

=cut

use constant LocalityIsRequired => '82618';

=item PostalCodeIsInvalid

=cut

use constant PostalCodeIsInvalid => '82630';

=item PostalCodeIsRequired

=cut

use constant PostalCodeIsRequired => '82619';

=item RegionIsRequired

=cut

use constant RegionIsRequired => '82620';

=item StreetAddressIsInvalid

=cut

use constant StreetAddressIsInvalid => '82629';

=item StreetAddressIsRequired

=cut

use constant StreetAddressIsRequired => '82617';

=item RegionIsInvalid

=cut

use constant RegionIsInvalid => '82664';

=back

=cut

1;
__END__
