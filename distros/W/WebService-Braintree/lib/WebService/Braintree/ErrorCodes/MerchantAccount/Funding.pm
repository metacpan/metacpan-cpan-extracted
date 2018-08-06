# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::Funding;
$WebService::Braintree::ErrorCodes::MerchantAccount::Funding::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::Funding

=head1 PURPOSE

This class contains error codes that might be returned if the funding
details for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item RoutingNumberIsRequired

=cut

use constant RoutingNumberIsRequired => '82640';

=item AccountNumberIsRequired

=cut

use constant AccountNumberIsRequired => '82641';

=item RoutingNumberIsInvalid

=cut

use constant RoutingNumberIsInvalid => '82649';

=item AccountNumberIsInvalid

=cut

use constant AccountNumberIsInvalid => '82671';

=item DestinationIsRequired

=cut

use constant DestinationIsRequired => '82678';

=item DestinationIsInvalid

=cut

use constant DestinationIsInvalid => '82679';

=item EmailIsRequired

=cut

use constant EmailIsRequired => '82680';

=item EmailIsInvalid

=cut

use constant EmailIsInvalid => '82681';

=item MobilePhoneIsRequired

=cut

use constant MobilePhoneIsRequired => '82682';

=item MobilePhoneIsInvalid

=cut

use constant MobilePhoneIsInvalid => '82683';

=back

=cut

1;
__END__
