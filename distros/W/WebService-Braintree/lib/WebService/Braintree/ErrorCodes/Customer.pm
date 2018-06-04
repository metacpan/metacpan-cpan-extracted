# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Customer;
$WebService::Braintree::ErrorCodes::Customer::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Customer

=head1 PURPOSE

This class contains error codes that might be returned if a customer is
incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item CompanyIsTooLong

=cut

use constant CompanyIsTooLong => '81601';

=item CustomFieldIsInvalid

=cut

use constant CustomFieldIsInvalid => '91602';

=item CustomFieldIsTooLong

=cut

use constant CustomFieldIsTooLong => '81603';

=item EmailIsInvalid

=cut

use constant EmailIsInvalid => '81604';

=item EmailFormatIsInvalid

=cut

use constant EmailFormatIsInvalid => '81604';

=item EmailIsRequired

=cut

use constant EmailIsRequired => '81606';

=item EmailIsTooLong

=cut

use constant EmailIsTooLong => '81605';

=item FaxIsTooLong

=cut

use constant FaxIsTooLong => '81607';

=item FirstNameIsTooLong

=cut

use constant FirstNameIsTooLong => '81608';

=item IdIsInUse

=cut

use constant IdIsInUse => '91609';

=item IdIsInvalid

=cut

use constant IdIsInvalid => '91610';

=item IdIsNotAllowed

=cut

use constant IdIsNotAllowed => '91611';

=item IdIsRequired

=cut

use constant IdIsRequired => '91613';

=item IdIsTooLong

=cut

use constant IdIsTooLong => '91612';

=item LastNameIsTooLong

=cut

use constant LastNameIsTooLong => '81613';

=item PhoneIsTooLong

=cut

use constant PhoneIsTooLong => '81614';

=item WebsiteIsInvalid

=cut

use constant WebsiteIsInvalid => '81616';

=item WebsiteFormatIsInvalid

=cut

use constant WebsiteFormatIsInvalid => '81616';

=item WebsiteIsTooLong

=cut

use constant WebsiteIsTooLong => '81615';

=back

=cut

1;
__END__
