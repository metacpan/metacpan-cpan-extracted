# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Address;
$WebService::Braintree::ErrorCodes::Address::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Address

=head1 PURPOSE

This class contains error codes that might be returned if an address
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CannotBeBlank

=cut

use constant CannotBeBlank => '81801';

=item CompanyIsInvalid

=cut

use constant CompanyIsInvalid => '91821';

=item CompanyIsTooLong

=cut

use constant CompanyIsTooLong => '81802';

=item CountryCodeAlpha2IsNotAccepted

=cut

use constant CountryCodeAlpha2IsNotAccepted => '91814';

=item CountryCodeAlpha3IsNotAccepted

=cut

use constant CountryCodeAlpha3IsNotAccepted => '91816';

=item CountryCodeNumericIsNotAccepted

=cut

use constant CountryCodeNumericIsNotAccepted => '91817';

=item CountryNameIsNotAccepted

=cut

use constant CountryNameIsNotAccepted => '91803';

=item ExtendedAddressIsInvalid

=cut

use constant ExtendedAddressIsInvalid => '91823';

=item ExtendedAddressIsTooLong

=cut

use constant ExtendedAddressIsTooLong => '81804';

=item FirstNameIsInvalid

=cut

use constant FirstNameIsInvalid => '91819';

=item FirstNameIsTooLong

=cut

use constant FirstNameIsTooLong => '81805';

=item InconsistentCountry

=cut

use constant InconsistentCountry => '91815';

=item LastNameIsInvalid

=cut

use constant LastNameIsInvalid => '91820';

=item LastNameIsTooLong

=cut

use constant LastNameIsTooLong => '81806';

=item LocalityIsInvalid

=cut

use constant LocalityIsInvalid => '91824';

=item LocalityIsTooLong

=cut

use constant LocalityIsTooLong => '81807';

=item PostalCodeInvalidCharacters

=cut

use constant PostalCodeInvalidCharacters => '81813';

=item PostalCodeIsInvalid

=cut

use constant PostalCodeIsInvalid => '91826';

=item PostalCodeIsRequired

=cut

use constant PostalCodeIsRequired => '81808';

=item PostalCodeIsTooLong

=cut

use constant PostalCodeIsTooLong => '81809';

=item RegionIsInvalid

=cut

use constant RegionIsInvalid => '91825';

=item RegionIsTooLong

=cut

use constant RegionIsTooLong => '81810';

=item StreetAddressIsInvalid

=cut

use constant StreetAddressIsInvalid => '91822';

=item StreetAddressIsRequired

=cut

use constant StreetAddressIsRequired => '81811';

=item StreetAddressIsTooLong

=cut

use constant StreetAddressIsTooLong => '81812';

=item TooManyAddressesPerCustomer

=cut

use constant TooManyAddressesPerCustomer => '91818';

=back

=cut

1;
__END__
