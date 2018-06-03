# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::IndustryType;
$WebService::Braintree::ErrorCodes::IndustryType::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::IndustryType

=head1 PURPOSE

This class contains error codes that might be returned if an industry type
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CheckInDateIsInvalid

=cut

use constant CheckInDateIsInvalid => '93404';

=item CheckOutDateIsInvalid

=cut

use constant CheckOutDateIsInvalid => '93405';

=item CheckOutDateMustFollowCheckInDate

=cut

use constant CheckOutDateMustFollowCheckInDate => '93406';

=item EmptyData

=cut

use constant EmptyData => '93402';

=item FolioNumberIsInvalid

=cut

use constant FolioNumberIsInvalid => '93403';

=item IndustryTypeIsInvalid

=cut

use constant IndustryTypeIsInvalid => '93401';

=item UnknownDataField

=cut

use constant UnknownDataField => '93407';

=back

=cut

1;
__END__
