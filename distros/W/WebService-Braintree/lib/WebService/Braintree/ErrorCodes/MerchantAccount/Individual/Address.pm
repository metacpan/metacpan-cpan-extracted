# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address;
$WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address

=head1 PURPOSE

This class contains error codes that might be returned if the address for an
individual record for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item StreetAddressIsRequired

=cut

use constant StreetAddressIsRequired => '82657';

=item LocalityIsRequired

=cut

use constant LocalityIsRequired => '82658';

=item PostalCodeIsRequired

=cut

use constant PostalCodeIsRequired => '82659';

=item RegionIsRequired

=cut

use constant RegionIsRequired => '82660';

=item StreetAddressIsInvalid

=cut

use constant StreetAddressIsInvalid => '82661';

=item PostalCodeIsInvalid

=cut

use constant PostalCodeIsInvalid => '82662';

=item RegionIsInvalid

=cut

use constant RegionIsInvalid => '82668';

=back

=cut

1;
__END__
