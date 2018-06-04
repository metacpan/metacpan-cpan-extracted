# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::WebhookNotification::Kind;
$WebService::Braintree::WebhookNotification::Kind::VERSION = '1.5';
use 5.010_001;
use strictures 1;

=head1 NAME

WebService::Braintree::WebhookNotification::Kind

=head1 PURPOSE

This class contains constants for the kinds of webhook notifications.

=cut

=head1 CONSTANTS

=over 4

=cut

=item PartnerMerchantConnected

=cut

use constant PartnerMerchantConnected => "partner_merchant_connected";

=item PartnerMerchantDisconnected

=cut

use constant PartnerMerchantDisconnected => "partner_merchant_disconnected";

=item PartnerMerchantDeclined

=cut

use constant PartnerMerchantDeclined => "partner_merchant_declined";

=item SubscriptionCanceled

=cut

use constant SubscriptionCanceled => "subscription_canceled";

=item SubscriptionChargedSuccessfully

=cut

use constant SubscriptionChargedSuccessfully => "subscription_charged_successfully";

=item SubscriptionChargedUnsuccessfully

=cut

use constant SubscriptionChargedUnsuccessfully => "subscription_charged_unsuccessfully";

=item SubscriptionExpired

=cut

use constant SubscriptionExpired => "subscription_expired";

=item SubscriptionTrialEnded

=cut

use constant SubscriptionTrialEnded => "subscription_trial_ended";

=item SubscriptionWentActive

=cut

use constant SubscriptionWentActive => "subscription_went_active";

=item SubscriptionWentPastDue

=cut

use constant SubscriptionWentPastDue => "subscription_went_past_due";

=item SubMerchantAccountApproved

=cut

use constant SubMerchantAccountApproved => "sub_merchant_account_approved";

=item SubMerchantAccountDeclined

=cut

use constant SubMerchantAccountDeclined => "sub_merchant_account_declined";

=item TransactionDisbursed

=cut

use constant TransactionDisbursed => "transaction_disbursed";

=item DisbursementException

=cut

use constant DisbursementException => "disbursement_exception";

=item Disbursement

=cut

use constant Disbursement => "disbursement";

=item DisputeOpened

=cut

use constant DisputeOpened => "dispute_opened";

=item DisputeLost

=cut

use constant DisputeLost => "dispute_lost";

=item DisputeWon

=cut

use constant DisputeWon => "dispute_won";

=item All

This returns an arrayref of all other constants in the order they are defined
in this module.

=cut

use constant All => (
    PartnerMerchantConnected,
    PartnerMerchantDisconnected,
    PartnerMerchantDeclined,
    SubscriptionCanceled,
    SubscriptionChargedSuccessfully,
    SubscriptionChargedUnsuccessfully,
    SubscriptionExpired,
    SubscriptionTrialEnded,
    SubscriptionWentActive,
    SubscriptionWentPastDue,
    SubMerchantAccountApproved,
    SubMerchantAccountDeclined,
    TransactionDisbursed,
    DisbursementException,
    Disbursement,
    DisputeOpened,
    DisputeLost,
    DisputeWon,
);

=back

=cut

1;
__END__
