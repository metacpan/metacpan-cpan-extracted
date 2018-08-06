# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Descriptor;
$WebService::Braintree::ErrorCodes::Descriptor::VERSION = '1.7';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Descriptor

=head1 PURPOSE

This class contains error codes that might be returned if a descriptor is
incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item DynamicDescriptorsDisabled

=cut

use constant DynamicDescriptorsDisabled => '92203';

=item InternationalPhoneFormatIsInvalid

=cut

use constant InternationalPhoneFormatIsInvalid => '92205';

=item InternationalNameFormatIsInvalid

=cut

use constant InternationalNameFormatIsInvalid => '92204';

=item NameFormatIsInvalid

=cut

use constant NameFormatIsInvalid => '92201';

=item PhoneFormatIsInvalid

=cut

use constant PhoneFormatIsInvalid => '92202';

=item UrlFormatIsInvalid

=cut

use constant UrlFormatIsInvalid => '92206';

=back

=cut

1;
__END__
