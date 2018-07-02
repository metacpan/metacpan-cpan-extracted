# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::MerchantAccount;
$WebService::Braintree::ErrorCodes::MerchantAccount::VERSION = '1.6';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::MerchantAccount

=head1 PURPOSE

This class contains error codes that might be returned if a merchant
account is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item IdIsNotAllowed

=cut

use constant IdIsNotAllowed => '82605';

=item IdIsTooLong

=cut

use constant IdIsTooLong => '82602';

=item IdFormatIsInvalid

=cut

use constant IdFormatIsInvalid => '82603';

=item MasterMerchantAccountIdIsInvalid

=cut

use constant MasterMerchantAccountIdIsInvalid => '82607';

=item IdIsInUse

=cut

use constant IdIsInUse => '82604';

=item MasterMerchantAccountIdIsRequired

=cut

use constant MasterMerchantAccountIdIsRequired => '82606';

=item MasterMerchantAccountMustBeActive

=cut

use constant MasterMerchantAccountMustBeActive => '82608';

=item TosAcceptedIsRequired

=cut

use constant TosAcceptedIsRequired => '82610';

=item IdCannotBeUpdated

=cut

use constant IdCannotBeUpdated => '82675';

=item MasterMerchantAccountIdCannotBeUpdated

=cut

use constant MasterMerchantAccountIdCannotBeUpdated => '82676';

=item CannotBeUpdated

=cut

use constant CannotBeUpdated => '82674';

=item Declined

=cut

use constant Declined => '82626';

=item DeclinedMasterCardMatch

=cut

use constant DeclinedMasterCardMatch => '82622';

=item DeclinedOFAC

=cut

use constant DeclinedOFAC => '82621';

=item DeclinedFailedKYC

=cut

use constant DeclinedFailedKYC => '82623';

=item DeclinedSsnInvalid

=cut

use constant DeclinedSsnInvalid => '82624';

=item DeclinedSsnMatchesDeceased

=cut

use constant DeclinedSsnMatchesDeceased => '82625';

=back

=cut

1;
__END__
