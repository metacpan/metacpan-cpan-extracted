# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Subscription;
$WebService::Braintree::ErrorCodes::Subscription::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Subscription

=head1 PURPOSE

This class contains error codes that might be returned if a subscription
is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item BillingDayOfMonthCannotBeUpdated

=cut

use constant BillingDayOfMonthCannotBeUpdated => '91918';

=item BillingDayOfMonthIsInvalid

=cut

use constant BillingDayOfMonthIsInvalid => '91914';

=item BillingDayOfMonthMustBeNumeric

=cut

use constant BillingDayOfMonthMustBeNumeric => '91913';

=item CannotAddDuplicateAddonOrDiscount

=cut

use constant CannotAddDuplicateAddonOrDiscount => '91911';

=item CannotEditCanceledSubscription

=cut

use constant CannotEditCanceledSubscription => '81901';

=item CannotEditExpiredSubscription

=cut

use constant CannotEditExpiredSubscription => '81910';

=item CannotEditPriceChangingFieldsOnPastDueSubscription

=cut

use constant CannotEditPriceChangingFieldsOnPastDueSubscription => '91920';

=item FirstBillingDateCannotBeInThePast

=cut

use constant FirstBillingDateCannotBeInThePast => '91916';

=item FirstBillingDateCannotBeUpdated

=cut

use constant FirstBillingDateCannotBeUpdated => '91919';

=item FirstBillingDateIsInvalid

=cut

use constant FirstBillingDateIsInvalid => '91915';

=item IdIsInUse

=cut

use constant IdIsInUse => '81902';

=item InconsistentNumberOfBillingCycles

=cut

use constant InconsistentNumberOfBillingCycles => '91908';

=item InconsistentStartDate

=cut

use constant InconsistentStartDate => '91917';

=item InvalidRequestFormat

=cut

use constant InvalidRequestFormat => '91921';

=item MerchantAccountIdIsInvalid

=cut

use constant MerchantAccountIdIsInvalid => '91901';

=item MismatchCurrencyISOCode

=cut

use constant MismatchCurrencyISOCode => '91923';

=item NumberOfBillingCyclesCannotBeBlank

=cut

use constant NumberOfBillingCyclesCannotBeBlank => '91912';

=item NumberOfBillingCyclesIsTooSmall

=cut

use constant NumberOfBillingCyclesIsTooSmall => '91909';

=item NumberOfBillingCyclesMustBeGreaterThanZero

=cut

use constant NumberOfBillingCyclesMustBeGreaterThanZero => '91907';

=item NumberOfBillingCyclesMustBeNumeric

=cut

use constant NumberOfBillingCyclesMustBeNumeric => '91906';

=item PaymentMethodNonceCardTypeIsNotAccepted

=cut

use constant PaymentMethodNonceCardTypeIsNotAccepted => '91924';

=item PaymentMethodNonceIsInvalid

=cut

use constant PaymentMethodNonceIsInvalid => '91925';

=item PaymentMethodNonceNotAssociatedWithCustomer

=cut

use constant PaymentMethodNonceNotAssociatedWithCustomer => '91926';

=item PaymentMethodNonceUnvaultedCardIsNotAccepted

=cut

use constant PaymentMethodNonceUnvaultedCardIsNotAccepted => '91927';

=item PaymentMethodTokenCardTypeIsNotAccepted

=cut

use constant PaymentMethodTokenCardTypeIsNotAccepted => '91902';

=item PaymentMethodTokenIsInvalid

=cut

use constant PaymentMethodTokenIsInvalid => '91903';

=item PaymentMethodTokenNotAssociatedWithCustomer

=cut

use constant PaymentMethodTokenNotAssociatedWithCustomer => '91905';

=item PlanBillingFrequencyCannotBeUpdated

=cut

use constant PlanBillingFrequencyCannotBeUpdated => '91922';

=item PlanIdIsInvalid

=cut

use constant PlanIdIsInvalid => '91904';

=item PriceCannotBeBlank

=cut

use constant PriceCannotBeBlank => '81903';

=item PriceFormatIsInvalid

=cut

use constant PriceFormatIsInvalid => '81904';

=item PriceIsTooLarge

=cut

use constant PriceIsTooLarge => '81923';

=item StatusIsCanceled

=cut

use constant StatusIsCanceled => '81905';

=item TokenFormatIsInvalid

=cut

use constant TokenFormatIsInvalid => '81906';

=item TrialDurationFormatIsInvalid

=cut

use constant TrialDurationFormatIsInvalid => '81907';

=item TrialDurationIsRequired

=cut

use constant TrialDurationIsRequired => '81908';

=item TrialDurationUnitIsInvalid

=cut

use constant TrialDurationUnitIsInvalid => '81909';

=back

=cut

1;
__END__
