# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::ErrorCodes::Subscription::Modification;
$WebService::Braintree::ErrorCodes::Subscription::Modification::VERSION = '1.4';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::ErrorCodes::Subscription::Modification

=head1 PURPOSE

This class contains error codes that might be returned if a modification
of a subscription is incorrect in some way.

=cut

=head1 METHODS

=over 4

=cut

=item AmountCannotBeBlank

=cut

use constant AmountCannotBeBlank => '92003';

=item AmountIsInvalid

=cut

use constant AmountIsInvalid => '92002';

=item AmountIsTooLarge

=cut

use constant AmountIsTooLarge => '92023';

=item CannotEditModificationsOnPastDueSubscription

=cut

use constant CannotEditModificationsOnPastDueSubscription => '92022';

=item CannotUpdateAndRemove

=cut

use constant CannotUpdateAndRemove => '92015';

=item ExistingIdIsIncorrectKind

=cut

use constant ExistingIdIsIncorrectKind => '92020';

=item ExistingIdIsInvalid

=cut

use constant ExistingIdIsInvalid => '92011';

=item ExistingIdIsRequired

=cut

use constant ExistingIdIsRequired => '92012';

=item IdToRemoveIsIncorrectKind

=cut

use constant IdToRemoveIsIncorrectKind => '92021';

=item IdToRemoveIsInvalid

=cut

use constant IdToRemoveIsInvalid => '92025';

=item IdToRemoveIsNotPresent

=cut

use constant IdToRemoveIsNotPresent => '92016';

=item InconsistentNumberOfBillingCycles

=cut

use constant InconsistentNumberOfBillingCycles => '92018';

=item InheritedFromIdIsInvalid

=cut

use constant InheritedFromIdIsInvalid => '92013';

=item InheritedFromIdIsRequired

=cut

use constant InheritedFromIdIsRequired => '92014';

=item Missing

=cut

use constant Missing => '92024';

=item NumberOfBillingCyclesCannotBeBlank

=cut

use constant NumberOfBillingCyclesCannotBeBlank => '92017';

=item NumberOfBillingCyclesIsInvalid

=cut

use constant NumberOfBillingCyclesIsInvalid => '92005';

=item NumberOfBillingCyclesMustBeGreaterThanZero

=cut

use constant NumberOfBillingCyclesMustBeGreaterThanZero => '92019';

=item QuantityCannotBeBlank

=cut

use constant QuantityCannotBeBlank => '92004';

=item QuantityIsInvalid

=cut

use constant QuantityIsInvalid => '92001';

=item QuantityMustBeGreaterThanZero

=cut

use constant QuantityMustBeGreaterThanZero => '92010';

=back

=cut

1;
__END__
