# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount::Individual;
$WebService::Braintree::ErrorCodes::MerchantAccount::Individual::VERSION = '1.3';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount::Individual

=head1 PURPOSE

This class contains error codes that might be returned if an
individual record for a merchant account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item FirstNameIsRequired

=cut

use constant FirstNameIsRequired => '82637';

=item LastNameIsRequired

=cut

use constant LastNameIsRequired => '82638';

=item DateOfBirthIsRequired

=cut

use constant DateOfBirthIsRequired => '82639';

=item SsnIsInvalid

=cut

use constant SsnIsInvalid => '82642';

=item EmailIsInvalid

=cut

use constant EmailIsInvalid => '82643';

=item FirstNameIsInvalid

=cut

use constant FirstNameIsInvalid => '82644';

=item LastNameIsInvalid

=cut

use constant LastNameIsInvalid => '82645';

=item PhoneIsInvalid

=cut

use constant PhoneIsInvalid => '82656';

=item DateOfBirthIsInvalid

=cut

use constant DateOfBirthIsInvalid => '82666';

=item EmailIsRequired

=cut

use constant EmailIsRequired => '82667';

=back

=cut

1;
__END__
